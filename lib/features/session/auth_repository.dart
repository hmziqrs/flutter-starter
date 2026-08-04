import 'package:flutter/foundation.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/shared/errors/repository_exception.dart';

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

final class AuthException extends RepositoryException<AuthFailureKind> {
  const AuthException.notConnected() : super(kind: AuthFailureKind.notConnected);

  const AuthException.unauthorized([Object? cause])
    : super(kind: AuthFailureKind.unauthorized, cause: cause);

  const AuthException.unknown([Object? cause]) : super(kind: AuthFailureKind.unknown, cause: cause);

  @override
  String toString() => describe('AuthException');
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
