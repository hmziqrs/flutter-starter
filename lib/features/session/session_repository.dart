import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Thin typed wrapper over [SecureStore] for the refresh token only. No
/// `clearAll` — bulk wipes are forbidden. The access token is never
/// persisted; it lives only in memory on `AuthAuthenticated`.
final class SessionRepository {
  const SessionRepository(this._store);

  /// Single [SecureStore] key holding the persisted refresh token.
  static const String refreshTokenKey = 'session.refresh_token';

  final SecureStore _store;

  /// Reads the persisted refresh token, or `null` when none is stored. A
  /// [SecureStoreException] is swallowed as `null` — a storage failure must
  /// never tear down startup.
  Future<String?> readRefreshToken() async {
    try {
      return await _store.read(refreshTokenKey);
    } on SecureStoreException {
      return null;
    }
  }

  /// Persists [token]. Re-raises [SecureStoreException] so the controller can
  /// roll back its optimistic in-memory state.
  Future<void> writeRefreshToken(String token) => _store.write(refreshTokenKey, token);

  /// Removes any persisted refresh token. Re-raises [SecureStoreException];
  /// the controller treats a delete failure during logout as non-fatal.
  Future<void> deleteRefreshToken() => _store.delete(refreshTokenKey);
}
