enum ResetPasswordPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
}

/// Immutable, screen-specific fixture data for Reset Password.
final class ResetPasswordPresentationState {
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

  final ResetPasswordPresentationStatus status;
}
