import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/session/auth_session.dart';

part 'session_view_data.freezed.dart';

/// Typed presentation state for session UI surfaces (banners, profile chips,
/// the dev-gallery preview). Derived from [AuthSession] and never owns tokens
/// — only the user-facing summary (signed-in vs signed-out, display identity).
@freezed
class SessionViewData with _$SessionViewData {
  const SessionViewData({required this.isSignedIn, this.userId});

  /// Anonymous presentation: signed out, no identity.
  const SessionViewData.anonymous() : isSignedIn = false, userId = null;

  /// Derives the presentation state from a session. The exhaustive switch over
  /// the sealed [AuthSession] keeps strict analysis honest as the session
  /// family grows.
  factory SessionViewData.from(AuthSession session) {
    return switch (session) {
      AuthAnonymous() => const SessionViewData.anonymous(),
      AuthAuthenticated(:final userId) => SessionViewData(isSignedIn: true, userId: userId),
    };
  }

  /// Whether an authenticated session is held.
  @override
  final bool isSignedIn;

  /// The signed-in user's stable identity, or `null` when signed out.
  @override
  final String? userId;
}
