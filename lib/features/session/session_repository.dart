import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final class SessionRepository {
  SessionRepository(this._store, {AppLogger? logger}) : _logger = logger ?? AppLogger.bootstrap();

  static const String refreshTokenKey = 'session.refresh_token';

  final SecureStore _store;

  final AppLogger _logger;

  Future<String?> readRefreshToken() async {
    try {
      return await _store.read(refreshTokenKey);
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning(
        'session.read_token_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> writeRefreshToken(String token) => _store.write(refreshTokenKey, token);

  Future<void> deleteRefreshToken() => _store.delete(refreshTokenKey);
}
