import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_form_value.freezed.dart';

/// The exact six-digit code emitted by the OTP screen.
@freezed
abstract class OtpFormValue with _$OtpFormValue {
  const factory OtpFormValue({required String code}) = _OtpFormValue;
}
