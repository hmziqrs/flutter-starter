import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';

void main() {
  test('parses only the two registered OTP purposes', () {
    expect(OtpPurpose.tryParse('registration'), OtpPurpose.registration);
    expect(OtpPurpose.tryParse('password-reset'), OtpPurpose.passwordReset);
    expect(OtpPurpose.tryParse(null), isNull);
    expect(OtpPurpose.tryParse('reset'), isNull);
  });

  test('builds a canonical OTP location from a typed purpose', () {
    expect(AppRoutes.otpLocation(OtpPurpose.registration), '/auth/otp/registration');
    expect(AppRoutes.otpLocation(OtpPurpose.passwordReset), '/auth/otp/password-reset');
  });
}
