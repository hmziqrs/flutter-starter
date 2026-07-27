import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// In-memory [SecureStore] fake for tests, mirroring `InMemorySettingsStore`.
///
/// Test-only: never constructed in production code paths. The composition
/// root's `AppDependencies.inMemory` factory uses it as a peer of
/// `InMemorySettingsStore`, and unit tests drive the [SecureStore] contract
/// through it instead of hitting the real OS keychain.
///
/// Flip [failReads] / [failWrites] to surface [SecureStoreException] and
/// assert the wrapping behavior of upstream consumers.
final class InMemorySecureStore implements SecureStore {
  InMemorySecureStore({Map<String, String>? seed}) : _values = {...?seed};

  final Map<String, String> _values;

  /// When `true`, [read] throws [SecureStoreException] (writes/deletes still
  /// succeed).
  bool failReads = false;

  /// When `true`, [write] and [delete] throw [SecureStoreException] (reads
  /// still succeed).
  bool failWrites = false;

  /// Unmodifiable view of the live store contents for assertions.
  Map<String, String> get snapshot => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async {
    if (failReads) {
      throw SecureStoreException(operation: 'read', key: key);
    }
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) {
      throw SecureStoreException(operation: 'write', key: key);
    }
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failWrites) {
      throw SecureStoreException(operation: 'delete', key: key);
    }
    _values.remove(key);
  }
}
