import 'package:local_auth/local_auth.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Production [BiometricAuthenticator] backed by the `local_auth` OS plugin.
///
/// Constructed in `AppDependencies.production` (the composition root) only on
/// supported platforms; web / unsupported desktop / integration-test runs use
/// `NoopBiometricAuthenticator` instead, selected from `PlatformCapabilities`.
/// The plugin is never referenced outside this adapter — every consumer reads
/// the typed [BiometricAvailability] / `bool` surface (C2: no widget calls a
/// plugin directly).
///
/// Both methods degrade honestly inside `try/on Object` (C13: never fake
/// success): a failing availability check reports [BiometricAvailability.unavailable],
/// and a failing / cancelled prompt returns `false`. The plugin's own
/// `BiometricType` is mapped to the typed [BiometricKind] so the port surface
/// never leaks a plugin enum.
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

      // `canCheckBiometrics` is true only when at least one biometric is
      // enrolled and ready. `isDeviceSupported` adds the device-level
      // PIN/credential signal some platforms require. When either is missing we
      // distinguish "device has no biometric support" from "supported but
      // nothing enrolled" so the lock UI can route to the right fallback.
      if (!canCheckBiometrics || kinds.isEmpty) {
        final reason = isDeviceSupported
            ? BiometricUnavailableReason.notEnrolled
            : BiometricUnavailableReason.unsupported;
        return BiometricAvailability.unavailable(reason: reason, supportedBiometrics: kinds);
      }
      return BiometricAvailability.available(supportedBiometrics: kinds);
    } on Object {
      // Degrade honestly: the default unavailable reason is `unknown` (we could
      // not confirm biometrics), never a fabricated available report.
      return const BiometricAvailability.unavailable();
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          // stickyAuth so an interrupted prompt (app backgrounded mid-auth)
          // resumes rather than failing — important for a lock screen. The
          // defaults already allow device-credential (PIN/pattern/password)
          // fallback (biometricOnly: false), which is the "useFallback" OS-level
          // handoff mirroring the PIN-autolock pairing seam.
          stickyAuth: true,
        ),
      );
    } on Object {
      // Plugin error / missing platform binding — never fake success.
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
      // New / unknown platform values (e.g. a future deviceCredential kind) are
      // dropped rather than coerced to a wrong kind; availability stays honest.
      // The exhaustive list above covers every BiometricType in local_auth 2.x.
    };
  }
}
