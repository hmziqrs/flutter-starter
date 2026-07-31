import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_form_value.freezed.dart';

/// The normalized value emitted by the Forgot Password screen.
@freezed
abstract class ForgotPasswordFormValue with _$ForgotPasswordFormValue {
  const factory ForgotPasswordFormValue({required String email}) = _ForgotPasswordFormValue;
}
