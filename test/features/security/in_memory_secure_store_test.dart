import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Verifies the `failReads` / `failWrites` toggles and `snapshot` accessor of
/// [InMemorySecureStore] — the test fake that drives [SecureStore] contract
/// tests.
void main() {
  group('InMemorySecureStore toggles', () {
    test('failReads surfaces SecureStoreException on read only', () async {
      final store = InMemorySecureStore()..failReads = true;
      await store.write('session.refreshToken', 'abc-123');

      // Writes and deletes still succeed while only failReads is set.
      expect(store.snapshot, containsPair('session.refreshToken', 'abc-123'));
      expect(
        () => store.read('session.refreshToken'),
        throwsA(isA<SecureStoreException>()),
      );
      await store.delete('session.refreshToken');
      expect(store.snapshot, isNot(contains('session.refreshToken')));
    });

    test('failWrites surfaces SecureStoreException on write and delete', () async {
      final store = InMemorySecureStore(seed: {'session.refreshToken': 'abc-123'})
        ..failWrites = true;

      expect(
        () => store.write('analytics.optIn', 'true'),
        throwsA(isA<SecureStoreException>()),
      );
      expect(
        () => store.delete('session.refreshToken'),
        throwsA(isA<SecureStoreException>()),
      );
      // Reads still succeed while only failWrites is set.
      expect(await store.read('session.refreshToken'), 'abc-123');
      expect(store.snapshot, containsPair('session.refreshToken', 'abc-123'));
    });

    test('snapshot reflects the live store contents', () async {
      final store = InMemorySecureStore();
      await store.write('a', '1');
      await store.write('b', '2');

      expect(store.snapshot, {'a': '1', 'b': '2'});
    });

    test('snapshot is unmodifiable', () {
      final store = InMemorySecureStore();

      expect(() => store.snapshot['x'] = 'y', throwsUnsupportedError);
    });

    test('seed values are copied, not shared', () {
      final seed = <String, String>{'session.refreshToken': 'abc-123'};
      final store = InMemorySecureStore(seed: seed);
      seed['session.refreshToken'] = 'tampered';

      expect(store.snapshot['session.refreshToken'], 'abc-123');
    });

    test('toggling failReads off restores normal behavior', () async {
      final store = InMemorySecureStore()..failReads = true;
      await store.write('session.refreshToken', 'abc-123');

      expect(
        () => store.read('session.refreshToken'),
        throwsA(isA<SecureStoreException>()),
      );

      store.failReads = false;
      expect(await store.read('session.refreshToken'), 'abc-123');
    });

    test('toggling failWrites off restores normal behavior', () async {
      final store = InMemorySecureStore()..failWrites = true;

      expect(
        () => store.write('session.refreshToken', 'abc-123'),
        throwsA(isA<SecureStoreException>()),
      );

      store.failWrites = false;
      await store.write('session.refreshToken', 'abc-123');
      expect(await store.read('session.refreshToken'), 'abc-123');
    });
  });
}
