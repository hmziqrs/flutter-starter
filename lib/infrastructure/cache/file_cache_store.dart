import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

/// Production [CacheStore] backed by one JSON file per key under Application
/// Support (`SharedPreferences` is per-key small-string only and unsuitable
/// for payload blobs). No `sqflite` / `drift` / `hive` subsystem is
/// introduced.
///
/// The constructor takes a resolved [Directory] (via
/// [resolveApplicationSupportDirectory]) so the store itself is synchronous
/// and testable against a temp directory. Each key maps to
/// `<dir>/<base64url(key)>.json`: base64url-without-padding is
/// filesystem-safe, injective, and immune to path-traversal (a `/` or `..` in
/// a key is encoded, not interpreted).
///
/// Every operation is wrapped in `try/on Object -> CacheStoreException`.
/// Constructed only at the composition root.
final class FileCacheStore implements CacheStore {
  FileCacheStore(this._directory);

  final Directory _directory;

  /// Resolves the platform Application Support directory (the cache root).
  /// Web is unsupported by `path_provider` and must override
  /// [cacheStoreProvider] with `InMemoryCacheStore` instead.
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
    final encoded = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${_directory.path}/$encoded.json');
  }
}
