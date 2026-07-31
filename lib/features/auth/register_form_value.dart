import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_form_value.freezed.dart';

/// The normalized values emitted by the Register screen after native form validation.
///
/// The email address is trimmed at this boundary. Password values are preserved
/// exactly as entered and must never be persisted or logged.
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
