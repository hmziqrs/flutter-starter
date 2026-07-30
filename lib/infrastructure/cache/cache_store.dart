import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

/// Per-key local cache port, typed by [CacheEntry<T>] and persisted as JSON.
/// A feature supplies its own typed `fetch` and a [CacheCodec]; the
/// `cachedFutureProvider` helper composes this port with the shared
/// connectivity sensor to serve last-seen content when offline.
///
/// Deliberately no `clearAll` (per-key discipline) and no key enumeration —
/// the store persists whatever features write.
///
/// `SharedPreferences` is per-key small-string only and unsuitable for
/// payload blobs; the production adapter is `FileCacheStore` (one file per
/// key under Application Support). `InMemoryCacheStore` is the hermetic
/// default for tests and dev-gallery isolation.
abstract interface class CacheStore {
  /// Reads the cached entry for [key], or `null` if none exists. [codec]
  /// decodes the persisted value. A storage or parse failure is wrapped in
  /// [CacheStoreException].
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec});

  /// Writes (overwriting) the entry for [key]. A storage failure is wrapped
  /// in [CacheStoreException].
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec});

  /// Removes the entry for [key]. A no-op if the key is absent.
  Future<void> remove(String key);

  /// Elapsed since the entry at [key] was fetched, or `null` if absent.
  /// Codec-free — used by the diagnostics dump and "cached N minutes ago"
  /// affordances.
  Future<Duration?> age(String key);
}

/// Throws a [StateError] until the composition root overrides it
/// (`InMemoryCacheStore` for tests, `FileCacheStore` for
/// `AppDependencies.production`).
final cacheStoreProvider = Provider<CacheStore>(
  (ref) => throw StateError('CacheStore must be overridden at the composition root.'),
);
