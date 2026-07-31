import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';
import 'package:starter/infrastructure/cache/file_cache_store.dart';

const CacheCodec<String> _stringCodec = CacheCodec.string;

void main() {
  group('FileCacheStore contract', () {
    late Directory tempDir;
    late FileCacheStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_cache_store_test');
      store = FileCacheStore(tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('read returns null for an unknown key', () async {
      expect(await store.read<String>('cache.missing', codec: _stringCodec), isNull);
    });

    test('write then read round-trips the value', () async {
      final entry = CacheEntry<String>(
        value: 'hello',
        fetchedAt: DateTime.now().millisecondsSinceEpoch,
        ttlSeconds: 60,
      );

      await store.write('cache.greeting', entry, codec: _stringCodec);

      expect(await store.read<String>('cache.greeting', codec: _stringCodec), entry);
    });

    test('write overwrites the previous value for the same key', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.write(
        'cache.greeting',
        CacheEntry<String>(value: 'a', fetchedAt: now, ttlSeconds: 60),
        codec: _stringCodec,
      );
      await store.write(
        'cache.greeting',
        CacheEntry<String>(value: 'b', fetchedAt: now, ttlSeconds: 60),
        codec: _stringCodec,
      );

      expect((await store.read<String>('cache.greeting', codec: _stringCodec))!.value, 'b');
    });

    test('remove deletes the file', () async {
      await store.write(
        'cache.greeting',
        const CacheEntry<String>(value: 'a', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );

      await store.remove('cache.greeting');

      expect(await store.read<String>('cache.greeting', codec: _stringCodec), isNull);
    });

    test('remove is a no-op for an unknown key', () async {
      await store.remove('cache.never');
      expect(await store.read<String>('cache.never', codec: _stringCodec), isNull);
    });

    test('age is null for an absent key', () async {
      expect(await store.age('cache.absent'), isNull);
    });

    test('age reports elapsed since fetchedAt', () async {
      final fetchedAt = DateTime.now().millisecondsSinceEpoch - 5000;
      await store.write(
        'cache.greeting',
        CacheEntry<String>(value: 'a', fetchedAt: fetchedAt, ttlSeconds: 60),
        codec: _stringCodec,
      );

      final age = await store.age('cache.greeting');

      expect(age, isNotNull);
      expect(age!.inSeconds, greaterThanOrEqualTo(5));
    });

    test('two distinct keys map to two distinct files (no collision)', () async {
      await store.write(
        'cache.a',
        const CacheEntry<String>(value: '1', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );
      await store.write(
        'cache.b',
        const CacheEntry<String>(value: '2', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );

      expect((await store.read<String>('cache.a', codec: _stringCodec))!.value, '1');
      expect((await store.read<String>('cache.b', codec: _stringCodec))!.value, '2');
    });

    test('a hostile key with path separators cannot escape the cache root', () async {
      const hostile = '../etc/passwd';
      await store.write(
        hostile,
        const CacheEntry<String>(value: 'trapped', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );

      expect((await store.read<String>(hostile, codec: _stringCodec))!.value, 'trapped');
      expect(tempDir.listSync(recursive: true).whereType<File>().length, 1);
    });

    test('a corrupted file is wrapped as CacheStoreException on read', () async {
      await store.write(
        'cache.greeting',
        const CacheEntry<String>(value: 'a', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );
      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      await files.single.writeAsString('not json');

      expect(
        () => store.read<String>('cache.greeting', codec: _stringCodec),
        throwsA(isA<CacheStoreException>()),
      );
    });

    test('a payload missing numeric fields is wrapped as CacheStoreException', () async {
      final files = <File>[];
      await store.write(
        'cache.greeting',
        const CacheEntry<String>(value: 'a', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );
      files.addAll(tempDir.listSync().whereType<File>());
      await files.single.writeAsString('{"value":"a"}');

      expect(
        () => store.read<String>('cache.greeting', codec: _stringCodec),
        throwsA(isA<CacheStoreException>()),
      );
    });

    test('corrupted file on age() is wrapped as CacheStoreException', () async {
      await store.write(
        'cache.greeting',
        const CacheEntry<String>(value: 'a', fetchedAt: 0, ttlSeconds: 60),
        codec: _stringCodec,
      );
      final files = tempDir.listSync().whereType<File>().toList();
      await files.single.writeAsString('not json');

      expect(() => store.age('cache.greeting'), throwsA(isA<CacheStoreException>()));
    });
  });
}
