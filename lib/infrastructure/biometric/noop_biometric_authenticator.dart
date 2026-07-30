import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Deterministic "no biometric" [BiometricAuthenticator], selected for web,
/// unsupported desktop, and test runs. Reports unavailable/unsupported and
/// never returns a successful unlock; `LocalAuthAuthenticator` is the real
/// impl.
class NoopBiometricAuthenticator implements BiometricAuthenticator {
  const NoopBiometricAuthenticator();

  @override
  Future<BiometricAvailability> checkAvailability() async =>
      const BiometricAvailability.unavailable(reason: BiometricUnavailableReason.unsupported);

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}
