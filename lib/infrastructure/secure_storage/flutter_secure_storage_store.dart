import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// macOS reads silently return `null` without the Keychain Sharing entitlement; Android defaults require `minSdkVersion >= 23`.
final class FlutterSecureStorageStore implements SecureStore {
  FlutterSecureStorageStore()
    : _storage = const FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object {
      throw SecureStoreException(operation: 'read', key: key);
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on Object {
      throw SecureStoreException(operation: 'write', key: key);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on Object {
      throw SecureStoreException(operation: 'delete', key: key);
    }
  }
}
