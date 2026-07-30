import 'package:flutter/foundation.dart';

/// The authoritative session state, read by route guards, network clients, and
/// the UI. Sealed over [AuthAnonymous] and [AuthAuthenticated] so every
/// consumer switches exhaustively.
sealed class AuthSession {
  const AuthSession();

  /// True only when an authenticated session is held.
  bool get isAuthenticated;
}

/// No session is held: the cold-start default, the result of `logout`, and
/// the rolled-back state when `login` persistence fails.
@immutable
final class AuthAnonymous extends AuthSession {
  const AuthAnonymous();

  @override
  bool get isAuthenticated => false;

  @override
  bool operator ==(Object other) => other is AuthAnonymous;

  @override
  int get hashCode => 'AuthAnonymous'.hashCode;
}

/// An authenticated session. Tokens are secrets: the access token lives only
/// in memory, the refresh token is persisted via `SessionRepository` over
/// `SecureStore`, and any log line touching them flows through `AppLogger` so
/// `LogRedactor` scrubs them.
@immutable
final class AuthAuthenticated extends AuthSession {
  const AuthAuthenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  /// Short-lived bearer token. Held only in memory; never persisted.
  final String accessToken;

  /// Longer-lived refresh token, persisted so the session survives cold
  /// start; rotated on every successful `refresh`.
  final String refreshToken;

  /// When the [accessToken] expires.
  final DateTime expiresAt;

  /// Stable identity of the signed-in user, inherited across token rotations.
  final String userId;

  /// Whether the access token has expired (the session is still held; the
  /// foreground-refresh path calls `refresh` to re-validate).
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  AuthAuthenticated copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? userId,
  }) {
    return AuthAuthenticated(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool get isAuthenticated => true;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthAuthenticated &&
            accessToken == other.accessToken &&
            refreshToken == other.refreshToken &&
            expiresAt == other.expiresAt &&
            userId == other.userId;
  }

  @override
  int get hashCode => Object.hash(accessToken, refreshToken, expiresAt, userId);
}
