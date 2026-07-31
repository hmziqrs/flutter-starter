import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_form_value.freezed.dart';

@freezed
abstract class RegisterFormValue with _$RegisterFormValue {
  const factory RegisterFormValue({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) = _RegisterFormValue;
}
