import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';

/// Thrown when the device is offline (or the link is `limited`/unknown) and
/// no cached entry exists — nothing to serve and no way to refresh. Distinct
/// from `CacheStoreException` (a storage failure). Consumers map this to
/// `common.notConnected`.
final class CacheUnavailable implements Exception {
  const CacheUnavailable({this.key});

  /// The cache key that could not be served.
  final String? key;

  @override
  String toString() =>
      'CacheUnavailable: no cached entry and no connection${key == null ? '' : " for '$key'"}';
}

/// The read-through result of [buildCachedFutureProvider]. Carries the
/// resolved [CacheEntry] (when one exists) and its [CacheStatus] so the
/// consumer can show "showing saved content" for stale data rather than
/// presenting it as fresh.
final class CachedValue<T> {
  const CachedValue._({required this.entry, required this.status, this.updated = false});

  /// A fresh value served from the source (or a non-expired cache hit).
  factory CachedValue.fresh(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh, updated: true);

  /// A non-expired cache hit served without a refresh.
  factory CachedValue.cached(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh);

  /// An expired entry served because the device is offline (or the refresh
  /// failed): present but marked stale.
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

/// Parameters for [buildCachedFutureProvider].
final class CachedFutureSpec<T> {
  const CachedFutureSpec({
    required this.key,
    required this.fetch,
    required this.codec,
    required this.ttlSeconds,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  /// Cache key the entry is stored under.
  final String key;

  /// The feature-supplied typed remote source. On throw, the cache serves
  /// stale (or [CacheStatus.absent]).
  final Future<T> Function() fetch;

  /// Typed JSON (de)serialization for [T].
  final CacheCodec<T> codec;

  /// Fresh TTL in seconds applied to every freshly fetched entry.
  final int ttlSeconds;
}

/// Builds a read-through [FutureProvider] for one cached value.
///
/// Read order: a fresh cache hit is served without touching the network;
/// otherwise refresh is gated on the shared [connectivityStatusProvider] —
/// offline serves the stale entry (or throws [CacheUnavailable] if absent),
/// online runs [CachedFutureSpec.fetch] and writes the fresh entry back,
/// falling back to the stale entry on fetch failure.
///
/// A storage read/write failure never strands the read: a read failure is
/// treated as absent, a write failure is ignored.
///
/// A factory rather than a `.family`, since a handwritten Riverpod family
/// can't express a generic element type — each consumer owns the returned
/// provider as a `static final` field.
FutureProvider<CachedValue<T>> buildCachedFutureProvider<T>(CachedFutureSpec<T> spec) {
  return FutureProvider<CachedValue<T>>((ref) async {
    final store = ref.watch(cacheStoreProvider);
    final now = clock.now();

    CacheEntry<T>? cached;
    try {
      cached = await store.read<T>(spec.key, codec: spec.codec);
    } on Object {
      cached = null;
    }

    if (cached != null && cached.statusAt(now) == CacheStatus.fresh) {
      return CachedValue<T>.cached(cached);
    }

    final connectivity = ref.watch(connectivityStatusProvider).value;
    final canRefresh = connectivity == ConnectivityState.online;

    if (!canRefresh) {
      if (cached != null) {
        return CachedValue<T>.stale(cached);
      }
      throw CacheUnavailable(key: spec.key);
    }

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
        // Write failure must not prevent serving the freshly fetched value.
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
