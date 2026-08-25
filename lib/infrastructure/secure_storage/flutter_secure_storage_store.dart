import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/shared/async/storage_guard.dart';

final class FlutterSecureStorageStore implements SecureStore {
  FlutterSecureStorageStore()
    : _storage = const FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  final FlutterSecureStorage _storage;

  static Never _fail(Object error, String operation, String key) =>
      throw SecureStoreException(operation: operation, key: key);

  @override
  Future<String?> read(String key) {
    return guardStorageOpAsync(
      operation: 'read',
      key: key,
      action: () => _storage.read(key: key),
      failure: _fail,
    );
  }

  @override
  Future<void> write(String key, String value) {
    return guardStorageOpAsync(
      operation: 'write',
      key: key,
      action: () => _storage.write(key: key, value: value),
      failure: _fail,
    );
  }

  @override
  Future<void> delete(String key) {
    return guardStorageOpAsync(
      operation: 'delete',
      key: key,
      action: () => _storage.delete(key: key),
      failure: _fail,
    );
  }
}
