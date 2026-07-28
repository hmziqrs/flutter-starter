import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Production [SecureStore] backed by `flutter_secure_storage`.
///
/// This is a real, local store — it writes to the OS keychain/keystore, not a
/// server. There is no Noop default and no fake of success: every operation
/// either returns the stored value (or `null`) or throws
/// [SecureStoreException]. Platform options are configured once here:
///
/// - iOS: `accessibility: KeychainAccessibility.first_unlock` (readable after
///   the first device unlock). Set explicitly because the plugin default is
///   `KeychainAccessibility.unlocked`.
/// - macOS: `usesDataProtectionKeychain: true` is the plugin default and so is
///   not restated here; it requires the Keychain Sharing entitlement (without
///   it reads silently return `null`).
/// - Android: the resolved `flutter_secure_storage` 10.x deprecates and
///   ignores `encryptedSharedPreferences` (the Jetpack Security library is
///   deprecated by Google). The default `AndroidOptions` now uses stronger
///   custom ciphers — AES/GCM/NoPadding for data with RSA/OAEP key wrapping,
///   API 23+ — which satisfies the spec's intent (OS-backed encrypted storage
///   requiring API 23+). The Android Gradle setup therefore only needs
///   `minSdkVersion >= 23`; no Jetpack Security Gradle wiring is required.
///
/// Constructed only at the composition root (`AppDependencies.production`).
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
