import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final class InMemorySecureStore implements SecureStore {
  InMemorySecureStore({Map<String, String>? seed}) : _values = {...?seed};

  final Map<String, String> _values;
  bool failReads = false;
  bool failWrites = false;

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
