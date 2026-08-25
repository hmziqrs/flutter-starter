import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';
import 'package:starter/shared/async/storage_guard.dart';

final class FileCacheStore implements CacheStore {
  FileCacheStore(this._directory);

  final Directory _directory;

  static Future<Directory> resolveApplicationSupportDirectory() {
    return getApplicationSupportDirectory();
  }

  static Never _fail(Object error, String operation, String key) =>
      throw CacheStoreException(operation: operation, key: key);

  @override
  Future<CacheEntry<T>?> read<T>(String key, {required CacheCodec<T> codec}) {
    final file = _fileFor(key);
    return guardStorageOpAsync<CacheEntry<T>?>(
      operation: 'read',
      key: key,
      action: () async {
        if (!file.existsSync()) {
          return null;
        }
        final raw = jsonDecode(await file.readAsString());
        return cacheEntryFromJson<T>(raw, codec);
      },
      failure: _fail,
    );
  }

  @override
  Future<void> write<T>(String key, CacheEntry<T> entry, {required CacheCodec<T> codec}) {
    final file = _fileFor(key);
    return guardStorageOpAsync<void>(
      operation: 'write',
      key: key,
      action: () async {
        await _directory.create(recursive: true);
        final json = cacheEntryToJson<T>(entry, codec);
        await file.writeAsString(jsonEncode(json), flush: true);
      },
      failure: _fail,
    );
  }

  @override
  Future<void> remove(String key) {
    final file = _fileFor(key);
    return guardStorageOpAsync<void>(
      operation: 'remove',
      key: key,
      action: () async {
        if (file.existsSync()) {
          await file.delete();
        }
      },
      failure: _fail,
    );
  }

  @override
  Future<Duration?> age(String key) {
    final file = _fileFor(key);
    return guardStorageOpAsync<Duration?>(
      operation: 'age',
      key: key,
      action: () async {
        if (!file.existsSync()) {
          return null;
        }
        final raw = jsonDecode(await file.readAsString());
        final fetchedAt = cacheEntryFetchedAt(raw);
        if (fetchedAt == null) {
          return null;
        }
        return Duration(milliseconds: clock.now().millisecondsSinceEpoch - fetchedAt);
      },
      failure: _fail,
    );
  }

  File _fileFor(String key) {
    final encoded = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${_directory.path}/$encoded.json');
  }
}
