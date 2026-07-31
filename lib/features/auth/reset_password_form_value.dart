import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_form_value.freezed.dart';

@freezed
abstract class ResetPasswordFormValue with _$ResetPasswordFormValue {
  const factory ResetPasswordFormValue({
    required String newPassword,
    required String confirmPassword,
  }) = _ResetPasswordFormValue;
}
