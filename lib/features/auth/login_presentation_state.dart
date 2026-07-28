/// Deterministic states supported by the Login screen and development gallery.
enum LoginPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
  locked,
}

/// Immutable, screen-specific fixture data for Login.
final class LoginPresentationState {
  const LoginPresentationState({
    this.status = LoginPresentationStatus.idle,
    this.successMessage,
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
  }) : assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  const LoginPresentationState.invalid()
    : status = LoginPresentationStatus.invalid,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.focused()
    : status = LoginPresentationStatus.focused,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.submitting()
    : status = LoginPresentationStatus.submitting,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.fieldFailure()
    : status = LoginPresentationStatus.fieldFailure,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.globalFailure()
    : status = LoginPresentationStatus.globalFailure,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.success({this.successMessage})
    : status = LoginPresentationStatus.success,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  /// Locked out after too many failed attempts. [lockedSeconds] drives the live
  /// countdown and submit gate; [attemptsRemaining] surfaces the plural label.
  const LoginPresentationState.locked({
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
  }) : status = LoginPresentationStatus.locked,
       successMessage = null,
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  final LoginPresentationStatus status;
  final String? successMessage;

  /// Failed attempts the user may still make before the next lockout. Surfaced
  /// via a non-destructive alert while not locked; zero once locked.
  final int attemptsRemaining;

  /// Whole seconds in the active lockout at construction. The page runs a live
  /// countdown from this value and disables submit while it is positive.
  final int lockedSeconds;
}
