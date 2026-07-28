/// OS-backed encrypted per-key secret store (Keychain / Keystore / DPAPI /
/// libsecret) for tokens, refresh tokens, PIN/biometric hashes, and any future
/// secret.
///
/// Mirrors the settings store shape exactly: per-key `read` / `write` /
/// `delete`, all `Future`-returning and throwing [SecureStoreException]. There
/// is **no `clearAll`** (the repo forbids bulk wipes); a wipe flow iterates
/// the known key set and calls `delete` per key.
abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Thrown by [SecureStore] implementations when the underlying plugin call
/// fails. The original plugin error is intentionally not exposed.
final class SecureStoreException implements Exception {
  const SecureStoreException({required this.operation, required this.key});

  final String operation;
  final String key;

  @override
  String toString() => 'SecureStoreException: $operation failed for $key';
}
