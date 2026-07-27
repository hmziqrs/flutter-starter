enum OtpPresentationStatus {
  empty,
  partial,
  pastedComplete,
  invalid,
  expired,
  resending,
  submitting,
  globalFailure,
  success,
  locked,
}

/// Immutable, screen-specific fixture data for OTP verification.
final class OtpPresentationState {
  const OtpPresentationState({
    this.status = OtpPresentationStatus.empty,
    this.resendSeconds = 0,
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
  }) : assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  const OtpPresentationState.partial({this.resendSeconds = 0})
    : status = OtpPresentationStatus.partial,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.pastedComplete({this.resendSeconds = 0})
    : status = OtpPresentationStatus.pastedComplete,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.invalid({this.resendSeconds = 0})
    : status = OtpPresentationStatus.invalid,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.expired({this.resendSeconds = 0})
    : status = OtpPresentationStatus.expired,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.resending()
    : status = OtpPresentationStatus.resending,
      resendSeconds = 0,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const OtpPresentationState.submitting({this.resendSeconds = 0})
    : status = OtpPresentationStatus.submitting,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.globalFailure({this.resendSeconds = 0})
    : status = OtpPresentationStatus.globalFailure,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.success({this.resendSeconds = 0})
    : status = OtpPresentationStatus.success,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  /// Locked out after too many failed OTP attempts. [lockedSeconds] drives the
  /// live countdown and submit gate; [attemptsRemaining] surfaces the plural.
  const OtpPresentationState.locked({this.lockedSeconds = 0})
    : status = OtpPresentationStatus.locked,
      resendSeconds = 0,
      attemptsRemaining = 0,
      assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  final OtpPresentationStatus status;
  final int resendSeconds;

  /// Failed attempts the user may still make before the next lockout. Surfaced
  /// via a non-destructive alert while not locked; zero once locked.
  final int attemptsRemaining;

  /// Whole seconds in the active lockout at construction. The page runs a live
  /// countdown from this value and disables submit while it is positive.
  final int lockedSeconds;
}
