import 'package:local_auth/local_auth.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Production [BiometricAuthenticator] backed by the `local_auth` OS plugin.
/// A failing availability check reports [BiometricAvailability.unavailable];
/// a failing / cancelled prompt returns `false`.
class LocalAuthAuthenticator implements BiometricAuthenticator {
  LocalAuthAuthenticator({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final platformBiometrics = await _localAuth.getAvailableBiometrics();
      final kinds = <BiometricKind>{
        for (final type in platformBiometrics) ?_mapKind(type),
      };

      // Distinguish "no biometric support" from "supported but nothing
      // enrolled" so the lock UI routes to the right fallback.
      if (!canCheckBiometrics || kinds.isEmpty) {
        final reason = isDeviceSupported
            ? BiometricUnavailableReason.notEnrolled
            : BiometricUnavailableReason.unsupported;
        return BiometricAvailability.unavailable(reason: reason, supportedBiometrics: kinds);
      }
      return BiometricAvailability.available(supportedBiometrics: kinds);
    } on Object {
      return const BiometricAvailability.unavailable();
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          // Resumes rather than failing an interrupted prompt (app
          // backgrounded mid-auth). Defaults already allow device-credential
          // fallback (biometricOnly: false).
          stickyAuth: true,
        ),
      );
    } on Object {
      return false;
    }
  }

  static BiometricKind? _mapKind(BiometricType type) {
    return switch (type) {
      BiometricType.fingerprint => BiometricKind.fingerprint,
      BiometricType.face => BiometricKind.face,
      BiometricType.iris => BiometricKind.iris,
      BiometricType.strong => BiometricKind.strong,
      BiometricType.weak => BiometricKind.weak,
      // Unknown platform values are dropped rather than coerced.
    };
  }
}
