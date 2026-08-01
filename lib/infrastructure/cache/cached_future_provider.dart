import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';

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

final class CachedFutureSpec<T> {
  const CachedFutureSpec({
    required this.key,
    required this.fetch,
    required this.codec,
    required this.ttlSeconds,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  final String key;

  final Future<T> Function() fetch;

  final CacheCodec<T> codec;

  final int ttlSeconds;
}

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
        // ignored
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
