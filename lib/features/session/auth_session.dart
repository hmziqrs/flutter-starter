import 'package:flutter/foundation.dart';

/// The authoritative session state, read by route guards, network clients, and
/// the UI.
///
/// Sealed so every consumer switches exhaustively over exactly two states —
/// [AuthAnonymous] (no session held) and [AuthAuthenticated] (tokens + identity
/// in memory). Modeled on `UpdateRequirement` (sealed + final subtypes) and the
/// value-object discipline of `SettingsState`: `@immutable`, `copyWith`, value
/// equality. The router's auth-required predicate reads [isAuthenticated]; it
/// never inspects token fields directly.
sealed class AuthSession {
  const AuthSession();

  /// True only when an authenticated session is held.
  bool get isAuthenticated;
}

/// No session is held. The cold-start default, the result of `logout`, and the
/// rolled-back state when `login` persistence fails. Carries no tokens and no
/// identity.
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

/// An authenticated session.
///
/// The access token lives only in memory; the refresh token is persisted via
/// `SessionRepository` over `SecureStore` so a cold start can rehydrate by
/// calling `refresh`. Tokens are secrets — every log line that touches them
/// flows through `AppLogger` so `LogRedactor` scrubs them; they are never
/// logged directly.
@immutable
final class AuthAuthenticated extends AuthSession {
  const AuthAuthenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
  });

  /// Short-lived bearer token used to authorize authenticated requests. Held
  /// only in memory; never persisted.
  final String accessToken;

  /// Longer-lived refresh token used to mint new access tokens. Persisted via
  /// `SessionRepository` so the session survives cold start; rotated on every
  /// successful `refresh`.
  final String refreshToken;

  /// When the [accessToken] expires. The foreground-refresh path re-validates
  /// once this passes.
  final DateTime expiresAt;

  /// Stable identity of the signed-in user, issued by the auth backend and
  /// inherited across token rotations.
  final String userId;

  /// Whether the access token has expired. The session is still held (the
  /// refresh token may still mint a new access token); the foreground-refresh
  /// path calls `refresh` to re-validate.
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
