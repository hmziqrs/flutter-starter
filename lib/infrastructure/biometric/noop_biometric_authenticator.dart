import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Deterministic, honest "no biometric" [BiometricAuthenticator].
///
/// The composition root selects this adapter for web, unsupported desktop, and
/// integration-test runs (keyed off `PlatformCapabilities`, never a global) so
/// the starter stays green and goldens stay stable without ever triggering the
/// platform biometric plugin. Per the no-backend / honest-feedback contracts
/// (C2 / C13) it reports [BiometricAvailability.unavailable] with
/// [BiometricUnavailableReason.unsupported] and returns `false` from
/// [authenticate] — it **never fakes a successful unlock**. There is no
/// optional real impl behind it; the production path on a supported platform
/// uses `LocalAuthAuthenticator` instead.
class NoopBiometricAuthenticator implements BiometricAuthenticator {
  const NoopBiometricAuthenticator();

  @override
  Future<BiometricAvailability> checkAvailability() async {
    return const BiometricAvailability.unavailable(
      reason: BiometricUnavailableReason.unsupported,
    );
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async => false;
}
