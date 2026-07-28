import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';

/// Surfaced by the offline-aware read primitive when the device is offline
/// (or the link is `limited`/unknown) **and** no cached entry exists, so a
/// consuming feature can map it to `common.notConnected` honestly (C13: never
/// fake success). Distinct from `CacheStoreException` (a storage failure) —
/// this means "nothing to serve and no way to refresh".
final class CacheUnavailable implements Exception {
  const CacheUnavailable({this.key});

  /// The cache key that could not be served.
  final String? key;

  @override
  String toString() =>
      'CacheUnavailable: no cached entry and no connection${key == null ? '' : " for '$key'"}';
}

/// The honest read-through result of [buildCachedFutureProvider].
///
/// Carries the resolved [CacheEntry] (when one exists) **and** its
/// [CacheStatus] so the consumer can show "showing saved content" for stale
/// data instead of presenting it as fresh (the spec's stale-serve contract,
/// not silent failure). An exhaustive `switch` on [status] is the intended read
/// pattern at the call site.
final class CachedValue<T> {
  const CachedValue._({required this.entry, required this.status, this.updated = false});

  /// A fresh value served from the source (or a non-expired cache hit).
  factory CachedValue.fresh(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh, updated: true);

  /// A non-expired cache hit served without a refresh.
  factory CachedValue.cached(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh);

  /// An expired entry served because the device is offline (or the refresh
  /// failed). Honest stale-serve: the value is present but marked stale.
  factory CachedValue.stale(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.stale);

  /// The resolved entry, or `null` when [status] is [CacheStatus.absent].
  final CacheEntry<T>? entry;

  /// Freshness of the served value. Drives the UI affordance.
  final CacheStatus status;

  /// Whether the value was just fetched from the source on this read (a refresh
  /// ran and succeeded). `false` when served from cache without a refresh.
  final bool updated;

  /// Convenience: the typed value when present, else `null`.
  T? get value => entry?.value;

  /// Whether this result is a stale-serve (`status == stale`).
  bool get isStale => status == CacheStatus.stale;

  @override
  String toString() => 'CachedValue<$T>(status: $status, updated: $updated)';
}

/// Parameters for [buildCachedFutureProvider]. Bundled so the provider reads as
/// one expression and a consumer can construct the params once and reuse them.
final class CachedFutureSpec<T> {
  const CachedFutureSpec({
    required this.key,
    required this.fetch,
    required this.codec,
    required this.ttlSeconds,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  /// Cache key the entry is stored under.
  final String key;

  /// The feature-supplied typed remote source. Never owned by the cache; the
  /// consuming feature is responsible for its own `common.notConnected`
  /// semantics at the HTTP layer. Without a real network source this throws
  /// and the cache serves stale (or [CacheStatus.absent]).
  final Future<T> Function() fetch;

  /// Typed JSON (de)serialization for [T].
  final CacheCodec<T> codec;

  /// Fresh TTL in seconds applied to every freshly fetched entry.
  final int ttlSeconds;
}

/// Builds a read-through [FutureProvider] for one cached value.
///
/// Read order (the offline-aware read primitive):
///
/// 1. **Fresh cache hit** — a non-expired entry is served as
///    [CachedValue.cached] without touching the network.
/// 2. **Stale or absent** — gate on the **shared** [connectivityStatusProvider]
///    (C4: never a second connectivity sensor):
///    - **Offline / `limited` / unknown** — serve the stale entry as
///      [CachedValue.stale] (honest stale-serve), or throw [CacheUnavailable]
///      when there is nothing to serve (offline **and** absent → the consumer
///      maps this to `common.notConnected`, C13).
///    - **Online** — run [CachedFutureSpec.fetch], write the fresh entry back
///      to the cache, and return [CachedValue.fresh]. On fetch failure, degrade
///      to [CachedValue.stale] when a cached entry exists; otherwise rethrow so
///      a genuine error surfaces instead of being hidden.
///
/// A storage read/write failure never strands the read: a read failure is
/// treated as "absent" (and the refresh proceeds), a write failure is ignored
/// (the freshly fetched value is still returned). Both are surfaced via the
/// store's `CacheStoreException` internally, not propagated.
///
/// This is a factory, not a literal `.family`: a handwritten Riverpod family
/// cannot express a generic element type, so each consumer owns the returned
/// provider as a `static final` field and the generic [T] is reified at the
/// call site — matching the spec's `cachedFutureProvider<T>(key, fetch)` shape.
FutureProvider<CachedValue<T>> buildCachedFutureProvider<T>(CachedFutureSpec<T> spec) {
  return FutureProvider<CachedValue<T>>((ref) async {
    final store = ref.watch(cacheStoreProvider);
    final now = clock.now();

    // Step 1: read the cached entry. A storage failure must not strand the
    // read — treat it as "absent" and fall through to the refresh path.
    CacheEntry<T>? cached;
    try {
      cached = await store.read<T>(spec.key, codec: spec.codec);
    } on Object {
      cached = null;
    }

    if (cached != null && cached.statusAt(now) == CacheStatus.fresh) {
      return CachedValue<T>.cached(cached);
    }

    // Step 2: stale or absent — gate the refresh on the shared connectivity
    // sensor (C4: reuse connectivityStatusProvider, do not redeclare it).
    final connectivity = ref.watch(connectivityStatusProvider).value;
    final canRefresh = connectivity == ConnectivityState.online;

    if (!canRefresh) {
      if (cached != null) {
        return CachedValue<T>.stale(cached);
      }
      // Offline AND absent: surface notConnected honestly (C13). The consumer
      // maps this AsyncError to common.notConnected; the cache never fabricates
      // a value.
      throw CacheUnavailable(key: spec.key);
    }

    // Step 3: online — refresh, write back, return fresh. On a fetch failure,
    // degrade to the stale entry if one exists so the read path stays
    // resilient; otherwise surface the error.
    try {
      final value = await spec.fetch();
      final entry = CacheEntry<T>(
        value: value,
        fetchedAt: now.millisecondsSinceEpoch,
        ttlSeconds: spec.ttlSeconds,
      );
      try {
        await store.write<T>(spec.key, entry, codec: spec.codec);
      } on Object {
        // A write failure must not prevent serving the freshly fetched value.
      }
      return CachedValue<T>.fresh(entry);
    } on Object {
      if (cached != null) {
        return CachedValue<T>.stale(cached);
      }
      rethrow;
    }
  });
}
