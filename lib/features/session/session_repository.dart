import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final class SessionRepository {
  const SessionRepository(this._store);

  static const String refreshTokenKey = 'session.refresh_token';

  final SecureStore _store;

  Future<String?> readRefreshToken() async {
    try {
      return await _store.read(refreshTokenKey);
    } on SecureStoreException {
      return null;
    }
  }

  Future<void> writeRefreshToken(String token) => _store.write(refreshTokenKey, token);

  Future<void> deleteRefreshToken() => _store.delete(refreshTokenKey);
}
