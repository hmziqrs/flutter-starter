/// The normalized values emitted by the Login screen after native form validation.
///
/// The email address is trimmed at this boundary. The password is preserved
/// exactly as entered and must never be persisted or logged.
final class LoginFormValue {
  const LoginFormValue({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  final String email;
  final String password;
  final bool rememberMe;
}
