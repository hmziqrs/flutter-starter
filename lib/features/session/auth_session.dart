import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

@freezed
sealed class AuthSession with _$AuthSession {
  const AuthSession._();

  const factory AuthSession.anonymous() = AuthAnonymous;

  const factory AuthSession.authenticated({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required String userId,
  }) = AuthAuthenticated;

  bool get isAuthenticated => this is AuthAuthenticated;
}

extension AuthAuthenticatedStatus on AuthAuthenticated {
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
