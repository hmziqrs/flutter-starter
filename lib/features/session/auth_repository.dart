import 'package:flutter/foundation.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

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

final class AuthException implements Exception {
  const AuthException.notConnected() : kind = AuthFailureKind.notConnected, cause = null;

  const AuthException.unauthorized([this.cause]) : kind = AuthFailureKind.unauthorized;

  const AuthException.unknown([this.cause]) : kind = AuthFailureKind.unknown;

  final AuthFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'AuthException(${kind.name})';
}

abstract interface class AuthRepository {
  Future<AuthSession> login(AuthCredentials credentials);

  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  });

  Future<AuthSession> refresh(AuthSession session);

  Future<AuthSession> logout(AuthSession session);
}
