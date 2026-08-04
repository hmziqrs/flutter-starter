import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_repository.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/state/app_lifecycle_listener.dart';
import 'package:starter/shared/state/optimistic_notifier.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw StateError('AuthRepository must be overridden at the composition root.'),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw StateError('SessionRepository must be overridden at the composition root.'),
);

final initialSessionProvider = Provider<AuthSession>((ref) => const AuthAnonymous());

final sessionControllerProvider = NotifierProvider<SessionController, AuthSession>(
  SessionController.new,
);

final class SessionController extends Notifier<AuthSession> with OptimisticNotifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionRepository get _sessionRepository => ref.read(sessionRepositoryProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  @override
  AuthSession build() {
    listenOnResume(ref, _safeRefreshIfExpired);
    return ref.watch(initialSessionProvider);
  }

  Future<void> login(AuthCredentials credentials) async {
    final session = await _repository.login(credentials);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session);
  }

  Future<void> establish(AuthAuthenticated session) async {
    await _apply(session);
  }

  Future<void> refreshIfExpired() async {
    final current = state;
    if (current is! AuthAuthenticated || !current.isExpired) {
      return;
    }
    await _refresh(current);
  }

  Future<void> refresh() async {
    final current = state;
    if (current is! AuthAuthenticated) {
      return;
    }
    await _refresh(current);
  }

  Future<void> _refresh(AuthAuthenticated current) async {
    final session = await _repository.refresh(current);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session);
  }

  Future<void> _apply(AuthAuthenticated next) async {
    await guardRollback(next, () => _sessionRepository.writeRefreshToken(next.refreshToken));
  }

  Future<void> logout() async {
    final previous = state;
    state = const AuthAnonymous();
    try {
      await _repository.logout(previous);
    } on AuthException catch (error, stackTrace) {
      _logger.warning(
        'Remote logout failed; completing local logout',
        error: error,
        stackTrace: stackTrace,
      );
    }
    try {
      await _sessionRepository.deleteRefreshToken();
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'Failed to delete refresh token during logout',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> hydrateFromSecureStore() async {
    final token = await _sessionRepository.readRefreshToken();
    if (token == null) {
      return;
    }
    final stub = AuthAuthenticated(
      accessToken: '',
      refreshToken: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: '',
    );
    try {
      await _refresh(stub);
    } on AuthException catch (error, stackTrace) {
      _logger.warning(
        'Stored refresh token rejected during hydration; clearing',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await _sessionRepository.deleteRefreshToken();
      } on Object catch (error, stackTrace) {
        _logger.warning(
          'Failed to delete rejected refresh token',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _safeRefreshIfExpired() async {
    try {
      await refreshIfExpired();
    } on AuthException catch (error, stackTrace) {
      _logger.warning(
        'Background session refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
