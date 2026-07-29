import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_repository.dart';

/// Handwritten Riverpod handle for the [AuthRepository] port.
///
/// Mirrors `settingsRepositoryProvider` / `secureStoreProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete
/// adapter. The no-backend default (`InMemoryAuthRepository`, unseeded) is
/// constructed in `AppDependencies.production` and wired in `lib/app/app.dart`
/// as a peer of the other port overrides. No codegen.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw StateError('AuthRepository must be overridden at the composition root.'),
);

/// Handwritten Riverpod handle for the [SessionRepository].
///
/// Constructed at the composition root over the already-overridden
/// `SecureStore` and wired in `lib/app/app.dart`. Throws a [StateError] until
/// overridden so a missing wiring fails loudly.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw StateError('SessionRepository must be overridden at the composition root.'),
);

/// Cold-start seed for the session. Mirrors `initialSettingsProvider`: pre-
/// resolved at the composition root so the controller resolves synchronously
/// on the first frame and the router redirect can read it as a fallback. The
/// honest default is [AuthAnonymous] — a cold start never fakes a session
/// (C2). Overridden at the [ProviderScope] with the bootstrap-resolved session
/// when the consumer wires a real adapter that can hydrate from the persisted
/// refresh token.
final initialSessionProvider = Provider<AuthSession>((ref) => const AuthAnonymous());

/// Publishes the single authoritative [AuthSession].
///
/// A handwritten `NotifierProvider` (no codegen), modeled on
/// `settingsControllerProvider`: it owns mutable session state with optimistic
/// in-memory updates and rollback on persistence failure (the
/// `SettingsController._replace` shape). Route guards, network clients, and the
/// UI all read this provider; nobody mutates a session except through the
/// methods below.
final sessionControllerProvider = NotifierProvider<SessionController, AuthSession>(
  SessionController.new,
);

/// Owns the single source of truth for the [AuthSession].
///
/// Optimistic update + rollback (mirrors `SettingsController._replace`):
/// `login` and `refresh` flip the in-memory session first, then persist the
/// refresh token; a persistence failure rolls the state back to the previous
/// session and rethrows so the UI never observes a half-state. `logout` clears
/// local state first and treats server-side invalidation as best-effort (a
/// network failure during logout must not strand the user in an authenticated
/// shell). Tokens are secrets — never logged directly here; the repository and
/// `AppLogger`/`LogRedactor` are the redaction choke points.
final class SessionController extends Notifier<AuthSession> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SessionRepository get _sessionRepository => ref.read(sessionRepositoryProvider);

  @override
  AuthSession build() {
    // Foreground refresh (lifecycle-observer): when the app returns to the
    // foreground, re-validate the session — the access token may have expired
    // while backgrounded. `inactive` / `hidden` are noisy (overlays, system
    // sheets) and never trigger a refresh. The refresh is fire-and-forget and
    // swallows AuthException so a background -> foreground transition never
    // crashes; the session stays in its prior state and the next gated action
    // surfaces any real failure through the normal error path.
    ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
      final wasResumed = previous?.isResumed ?? false;
      if (next.isResumed && !wasResumed) {
        unawaited(_safeRefreshIfExpired());
      }
    });
    return ref.watch(initialSessionProvider);
  }

  /// Exchanges [credentials] for a session and persists the refresh token.
  ///
  /// The repository call must succeed before state is touched — there is no
  /// optimistic "logged-in" to show before the tokens exist. On success the
  /// in-memory session is flipped and the refresh token persisted; a
  /// persistence failure rolls back to the previous session and rethrows.
  /// [AuthException] from the repository propagates to the caller.
  Future<void> login(AuthCredentials credentials) async {
    final previous = state;
    final session = await _repository.login(credentials);
    if (session is! AuthAuthenticated) {
      return;
    }
    await _apply(session, previous: previous);
  }

  /// Publishes an [AuthAuthenticated] session issued inline by a registration
  /// OTP verify (the backend activates the account and returns tokens in the
  /// verify response), persisting its refresh token. Reuses the optimistic
  /// [_apply] shape: state flips first, then the token is written, rolling back
  /// on a persistence failure. Distinct from [login] (no credential exchange —
  /// the session already exists).
  Future<void> establish(AuthAuthenticated session) async {
    await _apply(session, previous: state);
  }

  /// Re-validates the current session when its access token has expired.
  ///
  /// No-op for an anonymous session or a session whose access token is still
  /// valid. The lifecycle listener wires this to the `resumed` edge; callers
  /// may also invoke it directly before a gated action.
  Future<void> refreshIfExpired() async {
    final current = state;
    if (current is! AuthAuthenticated || !current.isExpired) {
      return;
    }
    await _refresh(current);
  }

  /// Rotates the current session's tokens regardless of expiry. Used by the
  /// cold-start hydration path and by callers that want a fresh access token
  /// on demand. [AuthException] propagates to the caller.
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

  /// Optimistic in-memory update + persistence (mirrors
  /// `SettingsController._replace`). Flips [next] first, then writes the
  /// refresh token; a `SecureStoreException` rolls state back to [previous]
  /// and rethrows so the UI never shows a session whose token did not persist.
  Future<void> _apply(AuthAuthenticated next, {required AuthSession previous}) async {
    state = next;
    try {
      await _sessionRepository.writeRefreshToken(next.refreshToken);
    } on Object {
      state = previous;
      rethrow;
    }
  }

  /// Server-side invalidation followed by local clear.
  ///
  /// Local state is cleared FIRST so the UI is never stuck on a session being
  /// torn down. The server invalidation is best-effort: a network failure
  /// ([AuthException]) is swallowed — the spec mandates the local clear
  /// regardless — and the persisted refresh token is removed when possible.
  /// The integrator may surface the swallowed failure through an
  /// `appLoggerProvider` when one is wired; the controller does not invent a
  /// logging seam.
  Future<void> logout() async {
    final previous = state;
    state = const AuthAnonymous();
    try {
      await _repository.logout(previous);
    } on AuthException {
      // Swallowed: local state is already anonymous, which is the correct end
      // state. The user clicked logout; surfacing a backend error here would
      // be confusing. The integrator wires a logger to record this remotely.
    }
    try {
      await _sessionRepository.deleteRefreshToken();
    } on Object {
      // Non-fatal: the token is server-invalidated when possible and the
      // in-memory copy is already gone. Stale keychain leftovers surface, at
      // worst, as a no-op hydrate on the next cold start.
    }
  }

  /// Cold-start hydration.
  ///
  /// Reads the persisted refresh token from `SecureStore` and, when one is
  /// present, asks the repository to mint a fresh session from it. With the
  /// no-backend default (unseeded `InMemoryAuthRepository`), the repository
  /// throws `AuthException.notConnected` and the session stays anonymous —
  /// never faked (C2). When the repository rejects an unknown / revoked
  /// refresh token, the stale local token is removed so the next cold start
  /// does not retry with a dead token.
  ///
  /// Fire-and-forget from the composition root (`createApplication` / the
  /// splash handoff); the redirect reads LIVE controller state, so the moment
  /// hydration resolves the session flips and subsequent navigations observe
  /// it. Folding this into the splash's startup future yields a bounce-free
  /// cold start; see the manifest bootstrap note.
  Future<void> hydrateFromSecureStore() async {
    final token = await _sessionRepository.readRefreshToken();
    if (token == null) {
      return;
    }
    final stub = AuthAuthenticated(
      accessToken: '',
      refreshToken: token,
      // Force the expired branch so `_refresh` actually rotates the token
      // rather than short-circuiting.
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      userId: '',
    );
    try {
      await _refresh(stub);
    } on AuthException {
      // No backend wired, or the refresh token was rejected. Either way the
      // session stays anonymous; drop the stale token so we don't retry it.
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
