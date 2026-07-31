import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_value.freezed.dart';

/// The normalized values emitted by the Login screen after native form validation.
///
/// The email address is trimmed at this boundary. The password is preserved
/// exactly as entered and must never be persisted or logged.
@freezed
abstract class LoginFormValue with _$LoginFormValue {
  const factory LoginFormValue({
    required String email,
    required String password,
    required bool rememberMe,
  }) = _LoginFormValue;
}
