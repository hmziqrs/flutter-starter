import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_value.freezed.dart';

@freezed
abstract class LoginFormValue with _$LoginFormValue {
  const factory LoginFormValue({
    required String email,
    required String password,
    required bool rememberMe,
  }) = _LoginFormValue;
}
