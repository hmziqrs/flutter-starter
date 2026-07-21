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
final class ForgotPasswordPresentationState {
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

  final ForgotPasswordPresentationStatus status;
}
