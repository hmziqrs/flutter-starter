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
