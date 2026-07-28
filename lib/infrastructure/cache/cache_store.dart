import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

/// Per-key local cache port.
///
/// Mirrors [`SettingsStore`](../../features/settings/settings_store.dart)
/// exactly in shape (per-key, `Future`-returning, exceptions wrapped in
/// [CacheStoreException], **no** `clearAll`) — but typed by [CacheEntry<T>]
/// and persisted as JSON. It is the offline-cache data primitive: a feature
/// supplies its own typed `fetch` and a [CacheCodec], and the
/// `cachedFutureProvider` helper composes this port with the shared
/// connectivity sensor to serve last-seen content when offline.
///
/// There is deliberately **no `clearAll`** (per-key discipline only, matching
/// `SettingsStore` / `SecureStore`); a "clear cache" affordance iterates a
/// known key set and calls [remove] per key. There is also no key enumeration:
/// the store persists what features write, and a diagnostics dump (optional,
/// gated `developmentToolsEnabled`) takes the known key set from its caller.
///
/// `SharedPreferences` is per-key small-string only and unsuitable for payload
/// blobs; the production adapter is `FileCacheStore` (file-backed, one file per
/// key under Application Support). `InMemoryCacheStore` is the hermetic default
/// for tests and `PreviewFrame` / dev-gallery isolation (C2: real-local store,
/// never fakes a populated cache for a source that does not exist).
abstract interface class CacheStore {
  /// Reads the cached entry for [key], or `null` if none exists.
  ///
  /// [codec] decodes the persisted value into [T]; the store never interprets
  /// the payload. A storage or parse failure is wrapped in
  /// [CacheStoreException] — the caller never sees a plugin or `FileSystem`
  /// error.
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec});

  /// Writes (overwriting) the entry for [key]. [codec] encodes `entry.value`
  /// into its JSON form. A storage failure is wrapped in [CacheStoreException].
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec});

  /// Removes the entry for [key]. A no-op (not an error) if the key is absent,
  /// matching `SettingsStore.remove`. A storage failure is wrapped in
  /// [CacheStoreException].
  Future<void> remove(String key);

  /// Elapsed since the entry at [key] was fetched, or `null` if the key is
  /// absent. Reads only `fetchedAt` (no value decode), so it is cheap and
  /// codec-free — used by the optional diagnostics dump and by consumers that
  /// show a "cached N minutes ago" affordance.
  Future<Duration?> age(String key);
}

/// Handwritten Riverpod handle for the [CacheStore] port.
///
/// Mirrors `settingsStoreProvider` / `secureStoreProvider`: it throws a
/// [StateError] until the composition root overrides it. The composition root
/// wires `InMemoryCacheStore` for the in-memory / test factory and
/// `FileCacheStore` for `AppDependencies.production`; both are constructed in
/// [`AppDependencies`](../../app/dependencies.dart) and overridden at the
/// [`ProviderScope`](../../app/app.dart). No codegen.
final cacheStoreProvider = Provider<CacheStore>(
  (ref) => throw StateError('CacheStore must be overridden at the composition root.'),
);
