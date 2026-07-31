import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/session/auth_session.dart';

part 'session_view_data.freezed.dart';

@freezed
class SessionViewData with _$SessionViewData {
  const SessionViewData({required this.isSignedIn, this.userId});

  const SessionViewData.anonymous() : isSignedIn = false, userId = null;

  factory SessionViewData.from(AuthSession session) {
    return switch (session) {
      AuthAnonymous() => const SessionViewData.anonymous(),
      AuthAuthenticated(:final userId) => SessionViewData(isSignedIn: true, userId: userId),
    };
  }

  @override
  final bool isSignedIn;

  @override
  final String? userId;
}
