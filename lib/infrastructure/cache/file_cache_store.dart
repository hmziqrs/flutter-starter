import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

/// Production [CacheStore] backed by one JSON file per key.
///
/// This is the first non-`SharedPreferences` persistence adapter in the starter
/// — `SharedPreferences` is per-key small-string only and unsuitable for
/// payload blobs, so a file-per-key store under Application Support is the
/// sanctioned real-local cache (C2: real local store, not a Noop; never fakes
/// a populated cache for a source that does not exist). No `sqflite` / `drift`
/// / `hive` subsystem is introduced; a file per key is sufficient for a
/// starter.
///
/// The constructor takes a resolved [Directory] (resolved once at the
/// composition root via [resolveApplicationSupportDirectory]) so the store
/// itself is synchronous and testable against a temp directory. Each key maps
/// to `<dir>/<base64url(key)>.json`: base64url-without-padding is filesystem-
/// safe on every target, injective (no two keys collide), and immune to
/// path-traversal (a malicious `/` or `..` in a key is encoded, not
/// interpreted). The store never decodes the filename — it only ever maps a
/// key forward to its file.
///
/// Every operation is wrapped in `try/on Object -> CacheStoreException`,
/// mirroring [`FlutterSecureStorageStore`](../secure_storage/flutter_secure_storage_store.dart)
/// and [`SharedPreferencesSettingsStore`](../preferences/shared_preferences_settings_store.dart).
/// Constructed only at the composition root (`AppDependencies.production`).
final class FileCacheStore implements CacheStore {
  FileCacheStore(this._directory);

  final Directory _directory;

  /// Resolves the platform Application Support directory (the cache root).
  ///
  /// `path_provider`'s `getApplicationSupportDirectory` returns the app's
  /// sandboxed Application Support folder on every native target — the App
  /// Sandbox container is writable by default (macOS needs only
  /// `com.apple.security.app-sandbox`, already present; no extra entitlement).
  /// The composition root awaits this once, then constructs
  /// `FileCacheStore` with the result. Web is unsupported by `path_provider`
  /// and must override [cacheStoreProvider] with `InMemoryCacheStore`.
  static Future<Directory> resolveApplicationSupportDirectory() {
    return getApplicationSupportDirectory();
  }

  @override
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec}) async {
    final file = _fileFor(key);
    try {
      if (!file.existsSync()) {
        return null;
      }
      final raw = jsonDecode(await file.readAsString());
      return cacheEntryFromJson<T>(raw, codec);
    } on Object {
      throw CacheStoreException(operation: 'read', key: key);
    }
  }

  @override
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec}) async {
    final file = _fileFor(key);
    try {
      // `recursive: true` creates the cache root if it does not yet exist
      // (first write after install) and is a no-op otherwise.
      await _directory.create(recursive: true);
      final json = cacheEntryToJson<T>(entry, codec);
      await file.writeAsString(jsonEncode(json), flush: true);
    } on Object {
      throw CacheStoreException(operation: 'write', key: key);
    }
  }

  @override
  Future<void> remove(String key) async {
    final file = _fileFor(key);
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object {
      throw CacheStoreException(operation: 'remove', key: key);
    }
  }

  @override
  Future<Duration?> age(String key) async {
    final file = _fileFor(key);
    try {
      if (!file.existsSync()) {
        return null;
      }
      final raw = jsonDecode(await file.readAsString());
      final fetchedAt = cacheEntryFetchedAt(raw);
      if (fetchedAt == null) {
        return null;
      }
      return Duration(milliseconds: clock.now().millisecondsSinceEpoch - fetchedAt);
    } on Object {
      throw CacheStoreException(operation: 'age', key: key);
    }
  }

  File _fileFor(String key) {
    // base64url without padding: filesystem-safe, injective, and encodes any
    // `/` or `..` so a hostile key cannot escape the cache root.
    final encoded = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${_directory.path}/$encoded.json');
  }
}
