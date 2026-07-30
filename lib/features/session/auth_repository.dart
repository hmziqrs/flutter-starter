import 'package:flutter/foundation.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// Credentials submitted to [AuthRepository.login]. The password is never
/// trimmed — whitespace can be load-bearing in a passphrase.
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

/// Reasons an [AuthRepository] operation can fail, mapped to `session.*` i18n.
enum AuthFailureKind {
  /// No backend configured/reachable. The default for the unseeded
  /// `InMemoryAuthRepository` and any transport failure on the real adapter.
  notConnected,

  /// Credentials rejected, or the refresh token was revoked / expired.
  unauthorized,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [AuthRepository] operation; [cause] is
/// never a raw token.
final class AuthException implements Exception {
  const AuthException.notConnected() : kind = AuthFailureKind.notConnected, cause = null;

  const AuthException.unauthorized([this.cause]) : kind = AuthFailureKind.unauthorized;

  const AuthException.unknown([this.cause]) : kind = AuthFailureKind.unknown;

  final AuthFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'AuthException(${kind.name})';
}

/// The authentication port. No production impl is wired by default: the
/// `InMemoryAuthRepository` default surfaces `notConnected` when unseeded; the
/// optional real HTTP adapter implements this against
/// `POST /v1/auth/{issue,refresh,logout}` and rotates the refresh token on
/// every successful `refresh`.
abstract interface class AuthRepository {
  /// Exchanges [credentials] for a fresh [AuthSession]. The caller persists
  /// the returned refresh token via `SessionRepository`.
  Future<AuthSession> login(AuthCredentials credentials);

  /// Creates a pending account and issues a registration OTP, returning the
  /// issue handle so the caller can navigate to the OTP step. The account is
  /// activated and a session issued when that OTP is verified (arrives on
  /// [OtpVerifyResult.session]). `unauthorized` when the email is already
  /// registered.
  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  });

  /// Rotates [session]'s refresh token. The caller MUST persist the returned
  /// token — returning only the access token would break the
  /// issue -> refresh -> logout cycle. Throws when [session] is anonymous or
  /// the refresh token is unknown/revoked.
  Future<AuthSession> refresh(AuthSession session);

  /// Server-side invalidation of [session]'s refresh token; returns
  /// [AuthAnonymous]. The caller clears local state regardless of whether this
  /// succeeds — a network failure during logout must not strand the user in
  /// an authenticated shell.
  Future<AuthSession> logout(AuthSession session);
}
