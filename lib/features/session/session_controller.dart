import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_repository.dart';

/// Handwritten Riverpod handle for the [AuthRepository] port. Throws a
/// [StateError] until the composition root overrides it with a concrete
/// adapter; the no-backend default (`InMemoryAuthRepository`, unseeded) is
/// wired in `lib/app/app.dart`.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw StateError('AuthRepository must be overridden at the composition root.'),
);

/// Handwritten Riverpod handle for the [SessionRepository]. Throws a
/// [StateError] until overridden at the composition root.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw StateError('SessionRepository must be overridden at the composition root.'),
);

/// Cold-start seed for the session, pre-resolved so the controller resolves
/// synchronously on the first frame. The honest default is [AuthAnonymous] —
/// a cold start never fakes a session. Overridden at the [ProviderScope] with
/// the bootstrap-resolved session when a real adapter can hydrate from the
/// persisted refresh token.
final initialSessionProvider = Provider<AuthSession>((ref) => const AuthAnonymous());

/// Publishes the single authoritative [AuthSession]. Route guards, network
/// clients, and the UI all read this provider; nobody mutates a session
/// except through [SessionController]'s methods.
final sessionControllerProvider = NotifierProvider<SessionController, AuthSession>(
  SessionController.new,
);

/// Owns the single source of truth for the [AuthSession].
///
/// Optimistic update + rollback: `login` and `refresh` flip the in-memory
/// session first, then persist the refresh token; a persistence failure rolls
/// state back to the previous session and rethrows so the UI never observes a
/// half-state. `logout` clears local state first and treats server-side
/// invalidation as best-effort — a network failure during logout must not
/// strand the user in an authenticated shell.
final class SessionController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionRepository get _sessionRepository => ref.read(sessionRepositoryProvider);

  @override
  AuthSession build() {
    // Foreground refresh: re-validate on resume since the access token may
    // have expired while backgrounded. `inactive`/`hidden` (overlays, system
    // sheets) never trigger a refresh. Fire-and-forget; swallows
    // AuthException so a resume transition never crashes.
    ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
      final wasResumed = previous?.isResumed ?? false;
      if (next.isResumed && !wasResumed) {
        unawaited(_safeRefreshIfExpired());
      }
    });
    return ref.watch(initialSessionProvider);
  }

  /// Exchanges [credentials] for a session and persists the refresh token.
  /// The repository call must succeed before state is touched — there is no
  /// optimistic "logged-in" to show before the tokens exist.
  Future<void> login(AuthCredentials credentials) async {
    final previous = state;
    final session = await _repository.login(credentials);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session, previous: previous);
  }

  /// Publishes an [AuthAuthenticated] session issued inline by a registration
  /// OTP verify, persisting its refresh token. Distinct from [login]: no
  /// credential exchange, the session already exists.
  Future<void> establish(AuthAuthenticated session) async {
    await _apply(session, previous: state);
  }

  /// Re-validates the current session when its access token has expired.
  /// No-op for an anonymous session or one still valid.
  Future<void> refreshIfExpired() async {
    final current = state;
    if (current is! AuthAuthenticated || !current.isExpired) {
      return;
    }
    await _refresh(current);
  }

  /// Rotates the current session's tokens regardless of expiry.
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

  /// Optimistic in-memory update + persistence. Flips [next] first, then
  /// writes the refresh token; a `SecureStoreException` rolls state back to
  /// [previous] and rethrows so the UI never shows a session whose token did
  /// not persist.
  Future<void> _apply(AuthAuthenticated next, {required AuthSession previous}) async {
    state = next;
    try {
      await _sessionRepository.writeRefreshToken(next.refreshToken);
    } on Object {
      state = previous;
      rethrow;
    }
  }

  /// Server-side invalidation followed by local clear. Local state is cleared
  /// FIRST so the UI is never stuck on a session being torn down; the server
  /// invalidation and token removal are both best-effort.
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

  /// Cold-start hydration: reads the persisted refresh token and asks the
  /// repository to mint a fresh session from it. With the no-backend default
  /// the session stays anonymous — never faked. Fire-and-forget from the
  /// composition root; the redirect reads LIVE controller state.
  Future<void> hydrateFromSecureStore() async {
    final token = await _sessionRepository.readRefreshToken();
    if (token == null) {
      return;
    }
    final stub = AuthAuthenticated(
      accessToken: '',
      refreshToken: token,
      // Force the expired branch so `_refresh` rotates rather than
      // short-circuiting.
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: '',
    );
    try {
      await _refresh(stub);
    } on AuthException {
      // No backend, or the token was rejected; drop it so we don't retry.
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
      // Swallowed: foreground refresh is best-effort. The session retains its
      // prior state; the next gated action surfaces any real failure.
    }
  }
}
