import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

final class CacheUnavailable implements Exception {
  const CacheUnavailable({this.key});

  final String? key;

  @override
  String toString() =>
      'CacheUnavailable: no cached entry and no connection${key == null ? '' : " for '$key'"}';
}

final class CachedValue<T> {
  const CachedValue._({required this.entry, required this.status, this.updated = false});

  factory CachedValue.fresh(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh, updated: true);

  factory CachedValue.cached(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.fresh);

  factory CachedValue.stale(CacheEntry<T> entry) =>
      CachedValue._(entry: entry, status: CacheStatus.stale);

  final CacheEntry<T>? entry;

  final CacheStatus status;

  final bool updated;

  T? get value => entry?.value;

  bool get isStale => status == CacheStatus.stale;

  @override
  String toString() => 'CachedValue<$T>(status: $status, updated: $updated)';
}

/// Outcome of one cache fetch: new content, or an HTTP 304 "not modified".
sealed class CacheFetch<T> {
  const CacheFetch();
}

/// New content, optionally with its validator (`etag`) and server TTL.
final class CacheFetchModified<T> extends CacheFetch<T> {
  const CacheFetchModified({required this.value, this.etag, this.ttlSeconds});

  final T value;

  final String? etag;

  final int? ttlSeconds;
}

/// Content unchanged since the entry with the sent `etag`; fresh-extend it.
final class CacheFetchNotModified<T> extends CacheFetch<T> {
  const CacheFetchNotModified();
}

/// Receives the cached etag (null when nothing is cached) and reports whether
/// the content changed; backends map a `304` to [CacheFetchNotModified].
typedef CacheConditionalFetch<T> = Future<CacheFetch<T>> Function(String? etag);

final class CachedFutureSpec<T> {
  const CachedFutureSpec({
    required this.key,
    required this.fetch,
    required this.codec,
    required this.ttlSeconds,
    this.conditionalFetch,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  final String key;

  final Future<T> Function() fetch;

  /// When set, used instead of [fetch]: it receives the cached etag (null on
  /// the first population) so unchanged content short-circuits as a 304.
  final CacheConditionalFetch<T>? conditionalFetch;

  final CacheCodec<T> codec;

  final int ttlSeconds;
}

FutureProvider<CachedValue<T>> buildCachedFutureProvider<T>(CachedFutureSpec<T> spec) {
  return FutureProvider<CachedValue<T>>((ref) async {
    final store = ref.watch(cacheStoreProvider);
    final logger = ref.read(appLoggerProvider);
    final now = clock.now();

    CacheEntry<T>? cached;
    try {
      cached = await store.read<T>(spec.key, codec: spec.codec);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'cache.read_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'key': spec.key},
      );
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
      final conditional = spec.conditionalFetch;
      if (conditional != null) {
        // Conditional path: the cached etag (null on first population) lets the
        // fetch send `If-None-Match`; the first 200's etag + TTL are stored too.
        final prior = cached;
        final fetchedAt = clock.now().millisecondsSinceEpoch;
        switch (await conditional(prior?.etag)) {
          case CacheFetchNotModified<T>():
            if (prior == null) {
              throw const FormatException('Not-modified (304) without a cached entry.');
            }
            // 304: unchanged content — fresh-extend instead of re-downloading.
            final extended = CacheEntry<T>(
              value: prior.value,
              fetchedAt: fetchedAt,
              ttlSeconds: spec.ttlSeconds,
              etag: prior.etag,
            );
            await _persist(store, spec, extended, logger);
            return CachedValue<T>.cached(extended);
          case CacheFetchModified<T>(:final value, :final etag, :final ttlSeconds):
            final entry = CacheEntry<T>(
              value: value,
              fetchedAt: fetchedAt,
              ttlSeconds: ttlSeconds ?? spec.ttlSeconds,
              etag: etag,
            );
            await _persist(store, spec, entry, logger);
            return CachedValue<T>.fresh(entry);
        }
      }
      final value = await spec.fetch();
      final entry = CacheEntry<T>(
        value: value,
        fetchedAt: clock.now().millisecondsSinceEpoch,
        ttlSeconds: spec.ttlSeconds,
      );
      await _persist(store, spec, entry, logger);
      return CachedValue<T>.fresh(entry);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'cache.fetch_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'key': spec.key},
      );
      if (cached != null) {
        return CachedValue<T>.stale(cached);
      }
      rethrow;
    }
  });
}

Future<void> _persist<T>(
  CacheStore store,
  CachedFutureSpec<T> spec,
  CacheEntry<T> entry,
  AppLogger logger,
) async {
  try {
    await store.write<T>(spec.key, entry, codec: spec.codec);
  } on Object catch (error, stackTrace) {
    logger.warning(
      'cache.write_failed',
      error: error,
      stackTrace: stackTrace,
      context: {'key': spec.key},
    );
  }
}
