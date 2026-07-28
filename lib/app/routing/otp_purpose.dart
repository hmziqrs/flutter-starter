enum OtpPurpose {
  registration('registration'),
  passwordReset('password-reset'),
  mfa('mfa');

  const OtpPurpose(this.pathSegment);

  final String pathSegment;

  static OtpPurpose? tryParse(String? value) {
    return switch (value) {
      'registration' => OtpPurpose.registration,
      'password-reset' => OtpPurpose.passwordReset,
      'mfa' => OtpPurpose.mfa,
      _ => null,
    };
  }
}
