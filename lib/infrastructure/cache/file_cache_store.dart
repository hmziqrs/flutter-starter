import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';

final class FileCacheStore implements CacheStore {
  FileCacheStore(this._directory);

  final Directory _directory;

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
