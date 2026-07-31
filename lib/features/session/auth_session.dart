import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// The authoritative session state, read by route guards, network clients, and
/// the UI. Sealed over [AuthAnonymous] and [AuthAuthenticated] so every
/// consumer switches exhaustively.
@freezed
sealed class AuthSession with _$AuthSession {
  const AuthSession._();

  /// No session is held: the cold-start default, logout result, and rollback
  /// state when login persistence fails.
  const factory AuthSession.anonymous() = AuthAnonymous;

  /// An authenticated session. Tokens are secrets: the access token lives only
  /// in memory and the refresh token is persisted via `SessionRepository`.
  const factory AuthSession.authenticated({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required String userId,
  }) = AuthAuthenticated;

  /// True only when an authenticated session is held.
  bool get isAuthenticated => this is AuthAuthenticated;
}

extension AuthAuthenticatedStatus on AuthAuthenticated {
  /// Whether the access token has expired (the session is still held; the
  /// foreground-refresh path calls `refresh` to re-validate).
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
