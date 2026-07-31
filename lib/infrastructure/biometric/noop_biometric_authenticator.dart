import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

class NoopBiometricAuthenticator implements BiometricAuthenticator {
  const NoopBiometricAuthenticator();

  @override
  Future<BiometricAvailability> checkAvailability() async =>
      const BiometricAvailability.unavailable(reason: BiometricUnavailableReason.unsupported);

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}
