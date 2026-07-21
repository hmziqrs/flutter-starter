/// Deterministic states supported by the Login screen and development gallery.
enum LoginPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
}

/// Immutable, screen-specific fixture data for Login.
final class LoginPresentationState {
  const LoginPresentationState({
    this.status = LoginPresentationStatus.idle,
    this.successMessage,
  });

  const LoginPresentationState.invalid()
    : status = LoginPresentationStatus.invalid,
      successMessage = null;

  const LoginPresentationState.focused()
    : status = LoginPresentationStatus.focused,
      successMessage = null;

  const LoginPresentationState.submitting()
    : status = LoginPresentationStatus.submitting,
      successMessage = null;

  const LoginPresentationState.fieldFailure()
    : status = LoginPresentationStatus.fieldFailure,
      successMessage = null;

  const LoginPresentationState.globalFailure()
    : status = LoginPresentationStatus.globalFailure,
      successMessage = null;

  const LoginPresentationState.success({this.successMessage})
    : status = LoginPresentationStatus.success;

  final LoginPresentationStatus status;
  final String? successMessage;
}
