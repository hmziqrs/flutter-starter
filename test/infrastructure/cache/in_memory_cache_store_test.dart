import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store_exception.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';

/// A small typed value + codec to exercise the generic [CacheEntry<T>] path
/// and value equality (the [int] codec alone would not catch a regression that
/// dropped the generic).
@immutable
final class _Point {
  const _Point(this.x, this.y);
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

Object? _encodePoint(_Point p) => <String, Object?>{'x': p.x, 'y': p.y};

_Point _decodePoint(Object? json) {
  if (json is Map<String, Object?>) {
    final x = json['x'];
    final y = json['y'];
    if (x is int && y is int) {
      return _Point(x, y);
    }
  }
  return const _Point(0, 0);
}

Object? _encodeInt(int v) => v;

int _decodeInt(Object? json) => json is int ? json : 0;

const CacheCodec<_Point> _pointCodec = CacheCodec<_Point>(
  encode: _encodePoint,
  decode: _decodePoint,
);

const CacheCodec<int> _intCodec = CacheCodec<int>(encode: _encodeInt, decode: _decodeInt);

void main() {
  group('CacheEntry<T>', () {
    test('is value-equal across all four fields', () {
      const a = CacheEntry<_Point>(value: _Point(1, 2), fetchedAt: 100, ttlSeconds: 30);
      const b = CacheEntry<_Point>(value: _Point(1, 2), fetchedAt: 100, ttlSeconds: 30);
      const c = CacheEntry<_Point>(value: _Point(1, 2), fetchedAt: 100, ttlSeconds: 30, etag: 'e');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('statusAt is fresh before ttl elapses and stale after', () {
      const entry = CacheEntry<int>(value: 1, fetchedAt: 1000, ttlSeconds: 5);

      expect(entry.statusAt(DateTime.fromMillisecondsSinceEpoch(4000)), CacheStatus.fresh);
      expect(
        entry.statusAt(DateTime.fromMillisecondsSinceEpoch(5999)),
        CacheStatus.fresh,
      );
      expect(
        entry.statusAt(DateTime.fromMillisecondsSinceEpoch(6000)),
        CacheStatus.stale,
      );
    });

    test('ttlSeconds of zero is stale immediately', () {
      const entry = CacheEntry<int>(value: 1, fetchedAt: 1000, ttlSeconds: 0);

      expect(entry.statusAt(DateTime.fromMillisecondsSinceEpoch(1000)), CacheStatus.stale);
    });

    test('freshSecondsRemainingAt is clamped at zero once stale', () {
      const entry = CacheEntry<int>(value: 1, fetchedAt: 1000, ttlSeconds: 5);

      // expiresAt = 1000 + 5s = 6000ms; at 4000 → 2s left, at 6000 → 0.
      expect(entry.freshSecondsRemainingAt(DateTime.fromMillisecondsSinceEpoch(4000)), 2);
      expect(entry.freshSecondsRemainingAt(DateTime.fromMillisecondsSinceEpoch(6000)), 0);
    });

    test('ageAt reports elapsed since fetchedAt', () {
      const entry = CacheEntry<int>(value: 1, fetchedAt: 1000, ttlSeconds: 5);

      expect(entry.ageAt(DateTime.fromMillisecondsSinceEpoch(3500)).inMilliseconds, 2500);
    });

    test('negative ttlSeconds is rejected at construction', () {
      expect(
        () => CacheEntry<int>(value: 1, fetchedAt: 0, ttlSeconds: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('InMemoryCacheStore contract', () {
    late InMemoryCacheStore store;

    setUp(() {
      store = InMemoryCacheStore();
    });

    test('read returns null for an unknown key', () async {
      expect(await store.read<_Point>('cache.missing', codec: _pointCodec), isNull);
    });

    test('write then read round-trips the typed value', () async {
      final entry = CacheEntry<_Point>(
        value: const _Point(3, 4),
        fetchedAt: DateTime.now().millisecondsSinceEpoch,
        ttlSeconds: 60,
      );

      await store.write('_Point', entry, codec: _pointCodec);

      expect(await store.read<_Point>('_Point', codec: _pointCodec), entry);
    });

    test('round-trips a primitive int through the int codec', () async {
      final entry = CacheEntry<int>(
        value: 42,
        fetchedAt: DateTime.now().millisecondsSinceEpoch,
        ttlSeconds: 60,
      );

      await store.write('cache.count', entry, codec: _intCodec);

      expect(await store.read<int>('cache.count', codec: _intCodec), entry);
    });

    test('write overwrites the previous value for the same key', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.write<int>(
        'cache.count',
        CacheEntry<int>(value: 1, fetchedAt: now, ttlSeconds: 60),
        codec: _intCodec,
      );
      await store.write<int>(
        'cache.count',
        CacheEntry<int>(value: 2, fetchedAt: now, ttlSeconds: 60),
        codec: _intCodec,
      );

      expect((await store.read<int>('cache.count', codec: _intCodec))!.value, 2);
    });

    test('remove deletes the stored value', () async {
      await store.write<int>(
        'cache.count',
        const CacheEntry<int>(value: 1, fetchedAt: 0, ttlSeconds: 60),
        codec: _intCodec,
      );

      await store.remove('cache.count');

      expect(await store.read<int>('cache.count', codec: _intCodec), isNull);
    });

    test('remove is a no-op for an unknown key', () async {
      await store.remove('cache.never');
      expect(await store.read<int>('cache.never', codec: _intCodec), isNull);
    });

    test('age is null for an absent key', () async {
      expect(await store.age('cache.absent'), isNull);
    });

    test('age reports elapsed since fetchedAt', () async {
      final fetchedAt = DateTime.now().millisecondsSinceEpoch - 5000;
      await store.write<int>(
        'cache.count',
        CacheEntry<int>(value: 1, fetchedAt: fetchedAt, ttlSeconds: 60),
        codec: _intCodec,
      );

      final age = await store.age('cache.count');

      expect(age, isNotNull);
      expect(age!.inSeconds, greaterThanOrEqualTo(5));
    });

    test('read failure is wrapped in CacheStoreException', () async {
      store.failReads = true;

      expect(
        () => store.read<int>('cache.count', codec: _intCodec),
        throwsA(isA<CacheStoreException>()),
      );
    });

    test('write failure is wrapped in CacheStoreException', () async {
      store.failWrites = true;

      expect(
        () => store.write<int>(
          'cache.count',
          const CacheEntry<int>(value: 1, fetchedAt: 0, ttlSeconds: 1),
          codec: _intCodec,
        ),
        throwsA(isA<CacheStoreException>()),
      );
    });

    test('remove failure is wrapped in CacheStoreException', () async {
      store.failWrites = true;

      expect(() => store.remove('cache.count'), throwsA(isA<CacheStoreException>()));
    });

    test('age failure is wrapped in CacheStoreException', () async {
      store.failReads = true;

      expect(() => store.age('cache.count'), throwsA(isA<CacheStoreException>()));
    });

    test('CacheStoreException carries operation and key', () async {
      store.failWrites = true;
      CacheStoreException? captured;
      try {
        await store.write<int>(
          'cache.count',
          const CacheEntry<int>(value: 1, fetchedAt: 0, ttlSeconds: 1),
          codec: _intCodec,
        );
      } on CacheStoreException catch (error) {
        captured = error;
      }

      expect(captured, isNotNull);
      expect(captured!.operation, 'write');
      expect(captured.key, 'cache.count');
    });

    test('seeded payloads are readable', () async {
      final seeded = InMemoryCacheStore(
        seed: {
          'cache.count': <String, Object?>{
            'value': 9,
            'fetchedAt': 0,
            'ttlSeconds': 60,
          },
        },
      );

      final entry = await seeded.read<int>('cache.count', codec: _intCodec);

      expect(entry, isNotNull);
      expect(entry!.value, 9);
    });

    test('a corrupted seed payload wraps as CacheStoreException on read', () async {
      final corrupted = InMemoryCacheStore(
        seed: {
          'cache.bad': <String, Object?>{'value': 1}, // missing numeric fields
        },
      );

      expect(
        () => corrupted.read<int>('cache.bad', codec: _intCodec),
        throwsA(isA<CacheStoreException>()),
      );
    });
  });

  test('CacheStoreException toString includes operation and key', () {
    const exception = CacheStoreException(operation: 'read', key: 'cache.feature.x');

    expect(exception.toString(), 'CacheStoreException: read failed for cache.feature.x');
  });
}
