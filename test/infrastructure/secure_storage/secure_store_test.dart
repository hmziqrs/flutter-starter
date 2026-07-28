import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Exercises the [SecureStore] contract (round-trip read/write/delete plus
/// [SecureStoreException] wrapping) through the in-memory fake. Unit tests
/// never hit the real OS keychain; the production adapter applies the same
/// `try/on Object -> SecureStoreException` shape, verified by structural
/// parity with `SharedPreferencesSettingsStore`.
void main() {
  group('SecureStore contract', () {
    late InMemorySecureStore store;

    setUp(() {
      store = InMemorySecureStore();
    });

    test('read returns null for an unknown key', () async {
      expect(await store.read('session.refreshToken'), isNull);
    });

    test('write then read round-trips the value', () async {
      await store.write('session.refreshToken', 'abc-123');

      expect(await store.read('session.refreshToken'), 'abc-123');
    });

    test('write overwrites the previous value for the same key', () async {
      await store.write('session.refreshToken', 'abc-123');
      await store.write('session.refreshToken', 'xyz-789');

      expect(await store.read('session.refreshToken'), 'xyz-789');
    });

    test('delete removes the stored value', () async {
      await store.write('session.refreshToken', 'abc-123');
      await store.delete('session.refreshToken');

      expect(await store.read('session.refreshToken'), isNull);
    });

    test('delete is a no-op for an unknown key', () async {
      await store.delete('session.refreshToken');

      expect(await store.read('session.refreshToken'), isNull);
    });

    test('seeded values are readable', () async {
      final seeded = InMemorySecureStore(seed: {'analytics.optIn': 'true'});

      expect(await seeded.read('analytics.optIn'), 'true');
    });

    test('read failure is wrapped in SecureStoreException', () async {
      store.failReads = true;

      expect(() => store.read('session.refreshToken'), throwsA(isA<SecureStoreException>()));
    });

    test('write failure is wrapped in SecureStoreException', () async {
      store.failWrites = true;

      expect(
        () => store.write('session.refreshToken', 'abc-123'),
        throwsA(isA<SecureStoreException>()),
      );
    });

    test('delete failure is wrapped in SecureStoreException', () async {
      store.failWrites = true;

      expect(() => store.delete('session.refreshToken'), throwsA(isA<SecureStoreException>()));
    });

    test('SecureStoreException carries the operation and key', () async {
      store.failWrites = true;
      SecureStoreException? captured;
      try {
        await store.write('session.refreshToken', 'abc-123');
      } on SecureStoreException catch (error) {
        captured = error;
      }

      expect(captured, isNotNull);
      expect(captured!.operation, 'write');
      expect(captured.key, 'session.refreshToken');
    });
  });

  test('SecureStoreException toString includes operation and key', () {
    const exception = SecureStoreException(operation: 'read', key: 'session');

    expect(exception.toString(), 'SecureStoreException: read failed for session');
  });

  test('SecureStoreException preserves distinct identity per call', () {
    const first = SecureStoreException(operation: 'write', key: 'a');
    const second = SecureStoreException(operation: 'write', key: 'a');

    expect(first, equals(second));
    expect(first.toString(), second.toString());
  });
}
