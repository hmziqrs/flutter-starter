import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_presentation_state.freezed.dart';

enum ResetPasswordPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
}

@freezed
class ResetPasswordPresentationState with _$ResetPasswordPresentationState {
  const ResetPasswordPresentationState({
    this.status = ResetPasswordPresentationStatus.idle,
  });

  const ResetPasswordPresentationState.invalid() : status = ResetPasswordPresentationStatus.invalid;

  const ResetPasswordPresentationState.focused() : status = ResetPasswordPresentationStatus.focused;

  const ResetPasswordPresentationState.submitting()
    : status = ResetPasswordPresentationStatus.submitting;

  const ResetPasswordPresentationState.fieldFailure()
    : status = ResetPasswordPresentationStatus.fieldFailure;

  const ResetPasswordPresentationState.globalFailure()
    : status = ResetPasswordPresentationStatus.globalFailure;

  const ResetPasswordPresentationState.success() : status = ResetPasswordPresentationStatus.success;

  @override
  final ResetPasswordPresentationStatus status;
}
