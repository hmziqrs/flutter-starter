import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_form_value.freezed.dart';

/// The exact secret values emitted by the Reset Password screen.
@freezed
abstract class ResetPasswordFormValue with _$ResetPasswordFormValue {
  const factory ResetPasswordFormValue({
    required String newPassword,
    required String confirmPassword,
  }) = _ResetPasswordFormValue;
}
