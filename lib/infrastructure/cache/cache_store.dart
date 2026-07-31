import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';

abstract interface class CacheStore {
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec});

  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec});

  Future<void> remove(String key);

  Future<Duration?> age(String key);
}

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => throw StateError('CacheStore must be overridden at the composition root.'),
);
