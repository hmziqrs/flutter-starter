import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (`LocalAuthAuthenticator` on supported platforms,
/// `NoopBiometricAuthenticator` for web / unsupported / integration tests).
final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => throw StateError('BiometricAuthenticator must be overridden at the composition root.'),
);

/// Resolves the OS biometric availability once per [ProviderContainer].
/// Owned under `lib/infrastructure/` so every feature (security controller,
/// settings toggle, composition-root redirect) can read it without a
/// cross-feature import.
final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((ref) {
  return ref.watch(biometricAuthenticatorProvider).checkAvailability();
});
