import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => throw StateError('BiometricAuthenticator must be overridden at the composition root.'),
);

final biometricAvailabilityProvider = FutureProvider<BiometricAvailability>((ref) {
  return ref.watch(biometricAuthenticatorProvider).checkAvailability();
});
