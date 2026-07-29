import 'package:flutter/foundation.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// Credentials submitted to [AuthRepository.login]. A handwritten typed value:
/// never a `Map`, and the password is never trimmed (per the auth form
/// contract — whitespace can be load-bearing in a passphrase).
@immutable
final class AuthCredentials {
  const AuthCredentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthCredentials && email == other.email && password == other.password;
  }

  @override
  int get hashCode => Object.hash(email, password);
}

/// Reasons an [AuthRepository] operation can fail. Surfaced to the UI through
/// `AuthException` -> i18n; never leaked as a raw token. The honest no-backend
/// default surfaces [notConnected] rather than fabricating a session (C2).
enum AuthFailureKind {
  /// No backend is configured or reachable. The default for the unseeded
  /// `InMemoryAuthRepository` and for any transport failure on the real adapter.
  notConnected,

  /// Credentials rejected, or the refresh token was revoked / expired.
  unauthorized,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [AuthRepository] operation. Mirrors
/// `SettingsStoreException`: a typed reason the UI maps to `session.*` i18n
/// keys, with an optional underlying [cause] that is never a token (the
/// repository redacts before constructing this).
final class AuthException implements Exception {
  const AuthException.notConnected() : kind = AuthFailureKind.notConnected, cause = null;

  const AuthException.unauthorized([this.cause]) : kind = AuthFailureKind.unauthorized;

  const AuthException.unknown([this.cause]) : kind = AuthFailureKind.unknown;

  final AuthFailureKind kind;

  /// The underlying error, if any. Forwarded to crash reporting already
  /// redacted; never a raw token.
  final Object? cause;

  @override
  String toString() => 'AuthException(${kind.name})';
}

/// The authentication port.
///
/// Mirrors `SettingsStore` / `VersionGateStore`: per-operation, `Future`-
/// returning, throwing a typed [AuthException]. **No production impl is wired
/// by default** (the no-backend rule, C2): the `InMemoryAuthRepository`
/// default surfaces `AuthException.notConnected` when unseeded and never fakes
/// success. The optional real HTTP adapter — constructed in
/// `AppDependencies.production` only when the consumer provides an endpoint —
/// implements this against the test-server contract
/// (`POST /v1/auth/{issue,refresh,logout}`) and rotates the refresh token on
/// every successful `refresh`.
abstract interface class AuthRepository {
  /// Exchanges [credentials] for a fresh [AuthSession]. The returned session
  /// carries the issued refresh token; the caller persists it via
  /// `SessionRepository`. Throws [AuthException] on any failure.
  Future<AuthSession> login(AuthCredentials credentials);

  /// Creates a pending account for [credentials] + [displayName] and issues a
  /// registration OTP, returning the OTP issue handle so the caller can
  /// navigate to the OTP step and start its countdown. The account is activated
  /// and a session issued when the registration OTP is verified (the session
  /// arrives on [OtpVerifyResult.session]). Throws [AuthException] on any
  /// failure: `notConnected` when no backend is reachable, `unauthorized` when
  /// the email is already registered.
  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  });

  /// Rotates the refresh token carried by [session] and returns a new
  /// [AuthSession] with the new access + refresh tokens. The caller MUST
  /// persist the returned refresh token — returning only the access token
  /// would lose the rotated refresh and break the issue -> refresh -> logout
  /// cycle. Throws [AuthException] when [session] is anonymous or the refresh
  /// token is unknown / revoked.
  Future<AuthSession> refresh(AuthSession session);

  /// Server-side invalidation of [session]'s refresh token. Returns
  /// [AuthAnonymous]. Local state is cleared by the caller regardless of
  /// whether this succeeds: a network failure during logout must not strand
  /// the user in an authenticated shell. Throws [AuthException] only when no
  /// backend is reachable — the caller treats that as best-effort.
  Future<AuthSession> logout(AuthSession session);
}
