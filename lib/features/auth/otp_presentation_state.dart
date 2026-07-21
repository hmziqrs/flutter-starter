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
}

/// Immutable, screen-specific fixture data for OTP verification.
final class OtpPresentationState {
  const OtpPresentationState({
    this.status = OtpPresentationStatus.empty,
    this.resendSeconds = 0,
  }) : assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.partial({this.resendSeconds = 0})
    : status = OtpPresentationStatus.partial,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.pastedComplete({this.resendSeconds = 0})
    : status = OtpPresentationStatus.pastedComplete,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.invalid({this.resendSeconds = 0})
    : status = OtpPresentationStatus.invalid,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.expired({this.resendSeconds = 0})
    : status = OtpPresentationStatus.expired,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.resending()
    : status = OtpPresentationStatus.resending,
      resendSeconds = 0;

  const OtpPresentationState.submitting({this.resendSeconds = 0})
    : status = OtpPresentationStatus.submitting,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.globalFailure({this.resendSeconds = 0})
    : status = OtpPresentationStatus.globalFailure,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  const OtpPresentationState.success({this.resendSeconds = 0})
    : status = OtpPresentationStatus.success,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.');

  final OtpPresentationStatus status;
  final int resendSeconds;
}
