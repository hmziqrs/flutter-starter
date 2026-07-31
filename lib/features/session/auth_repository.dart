import 'package:flutter/foundation.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// The password is never trimmed — whitespace can be load-bearing in a passphrase.
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

enum AuthFailureKind {
  notConnected,

  unauthorized,

  unknown,
}

/// [cause] is never a raw access token.
final class AuthException implements Exception {
  const AuthException.notConnected() : kind = AuthFailureKind.notConnected, cause = null;

  const AuthException.unauthorized([this.cause]) : kind = AuthFailureKind.unauthorized;

  const AuthException.unknown([this.cause]) : kind = AuthFailureKind.unknown;

  final AuthFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'AuthException(${kind.name})';
}

/// HTTP adapter: POST /v1/auth/{issue,refresh,logout}.
abstract interface class AuthRepository {
  Future<AuthSession> login(AuthCredentials credentials);

  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  });

  /// Caller MUST persist the returned token, or the refresh cycle breaks.
  Future<AuthSession> refresh(AuthSession session);

  /// Caller must clear local state even on failure, or a network error strands the user.
  Future<AuthSession> logout(AuthSession session);
}
