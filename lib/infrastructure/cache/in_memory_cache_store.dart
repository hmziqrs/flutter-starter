import 'package:clock/clock.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

/// Deterministic in-memory [CacheStore].
///
/// The hermetic default for tests and `PreviewFrame` / dev-gallery isolation,
/// and the no-backend default constructed by `AppDependencies.inMemory`. Stores
/// each entry as its canonical [CacheEntryJson] map so it round-trips through
/// the codec exactly like `FileCacheStore` — the two adapters are
/// behaviorally identical, only the backing differs.
///
/// Mirrors [`InMemorySettingsStore`](../../features/settings/in_memory_settings_store.dart):
/// [failReads] / [failWrites] toggles let tests assert [CacheStoreException]
/// wrapping without Mocktail. Production never constructs this class except as
/// the in-memory factory default; it never fakes a populated cache for a source
/// that does not exist (C2 / C13) — entries only appear because a feature wrote
/// them.
final class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore({Map<String, CacheEntryJson>? seed}) : _entries = {...?seed};

  final Map<String, CacheEntryJson> _entries;

  /// When true, every [read] / [age] throws [CacheStoreException].
  bool failReads = false;

  /// When true, every [write] / [remove] throws [CacheStoreException].
  bool failWrites = false;

  /// Read-only snapshot of the raw stored payloads (for test assertions).
  Map<String, CacheEntryJson> get snapshot => Map.unmodifiable(_entries);

  /// Number of keys currently stored.
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
