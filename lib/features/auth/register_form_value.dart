/// The normalized values emitted by the Register screen after native form validation.
///
/// The email address is trimmed at this boundary. Password values are preserved
/// exactly as entered and must never be persisted or logged.
final class RegisterFormValue {
  const RegisterFormValue({
    required this.displayName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.acceptTerms,
  });

  final String displayName;
  final String email;
  final String password;
  final String confirmPassword;
  final bool acceptTerms;
}
