import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_presentation_state.freezed.dart';

enum ForgotPasswordPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
}

/// Immutable, screen-specific fixture data for Forgot Password.
@freezed
class ForgotPasswordPresentationState with _$ForgotPasswordPresentationState {
  const ForgotPasswordPresentationState({
    this.status = ForgotPasswordPresentationStatus.idle,
  });

  const ForgotPasswordPresentationState.invalid()
    : status = ForgotPasswordPresentationStatus.invalid;

  const ForgotPasswordPresentationState.focused()
    : status = ForgotPasswordPresentationStatus.focused;

  const ForgotPasswordPresentationState.submitting()
    : status = ForgotPasswordPresentationStatus.submitting;

  const ForgotPasswordPresentationState.fieldFailure()
    : status = ForgotPasswordPresentationStatus.fieldFailure;

  const ForgotPasswordPresentationState.globalFailure()
    : status = ForgotPasswordPresentationStatus.globalFailure;

  const ForgotPasswordPresentationState.success()
    : status = ForgotPasswordPresentationStatus.success;

  @override
  final ForgotPasswordPresentationStatus status;
}
