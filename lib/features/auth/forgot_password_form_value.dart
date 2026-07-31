import 'package:freezed_annotation/freezed_annotation.dart';

part 'forgot_password_form_value.freezed.dart';

@freezed
abstract class ForgotPasswordFormValue with _$ForgotPasswordFormValue {
  const factory ForgotPasswordFormValue({required String email}) = _ForgotPasswordFormValue;
}
