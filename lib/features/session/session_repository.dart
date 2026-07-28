import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Thin typed wrapper over [SecureStore] for the refresh token only.
///
/// Mirrors the per-key discipline of `SettingsRepository` / `SoftUpdateSnooze`:
/// a single known key ([refreshTokenKey]), `read` / `write` / `delete`, and
/// **no `clearAll`** (the repo forbids bulk wipes). The access token is never
/// persisted — it lives only in memory on `AuthAuthenticated`. Constructed at
/// the composition root with the production `FlutterSecureStorageStore` (or an
/// `InMemorySecureStore` in tests) and read by `SessionController` after every
/// successful `login` / `refresh` and during cold-start hydration.
final class SessionRepository {
  const SessionRepository(this._store);

  /// Single [SecureStore] key holding the persisted refresh token.
  static const String refreshTokenKey = 'session.refresh_token';

  final SecureStore _store;

  /// Reads the persisted refresh token, or `null` when none is stored.
  ///
  /// A [SecureStoreException] is swallowed and surfaced as `null`: the session
  /// feature treats an unreadable token as absent (the cold-start hydrate then
  /// surfaces `common.notConnected` rather than faking a session), and a
  /// storage failure must never tear down startup.
  Future<String?> readRefreshToken() async {
    try {
      return await _store.read(refreshTokenKey);
    } on SecureStoreException {
      return null;
    }
  }

  /// Persists [token] under [refreshTokenKey]. Re-raises [SecureStoreException]
  /// so the controller can roll back its optimistic in-memory state.
  Future<void> writeRefreshToken(String token) => _store.write(refreshTokenKey, token);

  /// Removes any persisted refresh token. Re-raises [SecureStoreException]; the
  /// controller treats a delete failure during logout as non-fatal.
  Future<void> deleteRefreshToken() => _store.delete(refreshTokenKey);
}
