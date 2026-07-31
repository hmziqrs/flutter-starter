import 'package:clock/clock.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

final class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore({Map<String, CacheEntryJson>? seed}) : _entries = {...?seed};

  final Map<String, CacheEntryJson> _entries;

  bool failReads = false;

  bool failWrites = false;

  Map<String, CacheEntryJson> get snapshot => Map.unmodifiable(_entries);

  int get size => _entries.length;

  @override
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec}) async {
    if (failReads) {
      throw CacheStoreException(operation: 'read', key: key);
    }
    final raw = _entries[key];
    if (raw == null) {
      return null;
    }
    try {
      return cacheEntryFromJson<T>(raw, codec);
    } on Object {
      throw CacheStoreException(operation: 'read', key: key);
    }
  }

  @override
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec}) async {
    if (failWrites) {
      throw CacheStoreException(operation: 'write', key: key);
    }
    try {
      _entries[key] = cacheEntryToJson<T>(entry, codec);
    } on Object {
      throw CacheStoreException(operation: 'write', key: key);
    }
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) {
      throw CacheStoreException(operation: 'remove', key: key);
    }
    _entries.remove(key);
  }

  @override
  Future<Duration?> age(String key) async {
    if (failReads) {
      throw CacheStoreException(operation: 'age', key: key);
    }
    final fetchedAt = cacheEntryFetchedAt(_entries[key]);
    if (fetchedAt == null) {
      return null;
    }
    return Duration(milliseconds: clock.now().millisecondsSinceEpoch - fetchedAt);
  }
}
