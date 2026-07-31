import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_repository.dart';

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

final class SessionController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionRepository get _sessionRepository => ref.read(sessionRepositoryProvider);

  @override
  AuthSession build() {
    ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
      final wasResumed = previous?.isResumed ?? false;
      if (next.isResumed && !wasResumed) {
        unawaited(_safeRefreshIfExpired());
      }
    });
    return ref.watch(initialSessionProvider);
  }

  Future<void> login(AuthCredentials credentials) async {
    final previous = state;
    final session = await _repository.login(credentials);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session, previous: previous);
  }

  Future<void> establish(AuthAuthenticated session) async {
    await _apply(session, previous: state);
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
    final previous = state;
    final session = await _repository.refresh(current);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session, previous: previous);
  }

  Future<void> _apply(AuthAuthenticated next, {required AuthSession previous}) async {
    state = next;
    try {
      await _sessionRepository.writeRefreshToken(next.refreshToken);
    } on Object {
      state = previous;
      rethrow;
    }
  }

  Future<void> logout() async {
    final previous = state;
    state = const AuthAnonymous();
    try {
      await _repository.logout(previous);
    } on AuthException {
      // Local state is already anonymous, the correct end state.
    }
    try {
      await _sessionRepository.deleteRefreshToken();
    } on Object {
      // Non-fatal: worst case is a no-op hydrate on the next cold start.
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
    } on AuthException {
      try {
        await _sessionRepository.deleteRefreshToken();
      } on Object {
        // Best-effort cleanup; non-fatal.
      }
    }
  }

  Future<void> _safeRefreshIfExpired() async {
    try {
      await refreshIfExpired();
    } on AuthException {
      // Swallowed: foreground refresh is best-effort; prior state retained.
    }
  }
}
