import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Handwritten Riverpod handle for the [BiometricAuthenticator] port.
///
/// Mirrors `settingsRepositoryProvider` / `secureStoreProvider` /
/// `versionGateStoreProvider`: it throws a [StateError] until the composition
/// root overrides it with a concrete adapter. The composition root selects the
/// real `LocalAuthAuthenticator` on supported platforms or the honest
/// `NoopBiometricAuthenticator` for web / unsupported / integration-test runs
/// (selected from `PlatformCapabilities` in `AppDependencies.production`, never
/// via a global), and wires the override in `lib/app/app.dart` as a peer of the
/// other port overrides.
final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => throw StateError('BiometricAuthenticator must be overridden at the composition root.'),
);

/// Resolves the OS biometric availability once per [ProviderContainer] through
/// the overridden [biometricAuthenticatorProvider].
///
/// Owned under `lib/infrastructure/` (not the security feature) so every feature
/// — the security controller, the settings toggle, and the composition-root
/// redirect — can read it without a cross-feature import. Mirrors
/// `versionCheckProvider`: the composition root selects the adapter (real on
/// supported platforms, `NoopBiometricAuthenticator` for web / unsupported /
/// integration tests) so this future resolves deterministically and never
/// triggers the platform plugin from a widget `build`.
final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((ref) {
  return ref.watch(biometricAuthenticatorProvider).checkAvailability();
});
