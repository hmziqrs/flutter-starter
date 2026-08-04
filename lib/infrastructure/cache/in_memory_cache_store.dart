import 'package:clock/clock.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';
import 'package:starter/shared/async/storage_guard.dart';

final class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore({Map<String, CacheEntryJson>? seed}) : _entries = {...?seed};

  final Map<String, CacheEntryJson> _entries;

  bool failReads = false;

  bool failWrites = false;

  Map<String, CacheEntryJson> get snapshot => Map.unmodifiable(_entries);

  int get size => _entries.length;

  static Never _fail(Object error, String operation, String key) =>
      throw CacheStoreException(operation: operation, key: key);

  @override
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec}) async {
    if (failReads) {
      throw CacheStoreException(operation: 'read', key: key);
    }
    final raw = _entries[key];
    if (raw == null) {
      return null;
    }
    return guardStorageOp<CacheEntry<T>?>(
      operation: 'read',
      key: key,
      action: () => cacheEntryFromJson<T>(raw, codec),
      failure: _fail,
    );
  }

  @override
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec}) async {
    if (failWrites) {
      throw CacheStoreException(operation: 'write', key: key);
    }
    guardStorageOp<void>(
      operation: 'write',
      key: key,
      action: () {
        _entries[key] = cacheEntryToJson<T>(entry, codec);
      },
      failure: _fail,
    );
  }

  @override
  Future<void> remove(String key) async {
    if (failWrites) {
      throw CacheStoreException(operation: 'remove', key: key);
    }
    guardStorageOp<void>(
      operation: 'remove',
      key: key,
      action: () {
        _entries.remove(key);
      },
      failure: _fail,
    );
  }

  @override
  Future<Duration?> age(String key) async {
    if (failReads) {
      throw CacheStoreException(operation: 'age', key: key);
    }
    return guardStorageOp<Duration?>(
      operation: 'age',
      key: key,
      action: () {
        final fetchedAt = cacheEntryFetchedAt(_entries[key]);
        if (fetchedAt == null) {
          return null;
        }
        return Duration(milliseconds: clock.now().millisecondsSinceEpoch - fetchedAt);
      },
      failure: _fail,
    );
  }
}
