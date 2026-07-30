import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Production [SecureStore] backed by `flutter_secure_storage` (OS
/// keychain/keystore, not a server). Every operation either returns the
/// stored value (or `null`) or throws [SecureStoreException].
///
/// - iOS: explicit `KeychainAccessibility.first_unlock` (plugin default is
///   `.unlocked`).
/// - macOS: requires the Keychain Sharing entitlement, or reads silently
///   return `null`.
/// - Android: `flutter_secure_storage` 10.x ignores `encryptedSharedPreferences`
///   (Jetpack Security is deprecated); its default `AndroidOptions` uses
///   AES/GCM/NoPadding with RSA/OAEP key wrapping, requiring `minSdkVersion >= 23`.
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
