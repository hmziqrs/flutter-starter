/// The exact secret values emitted by the Reset Password screen.
final class ResetPasswordFormValue {
  const ResetPasswordFormValue({
    required this.newPassword,
    required this.confirmPassword,
  });

  final String newPassword;
  final String confirmPassword;
}
