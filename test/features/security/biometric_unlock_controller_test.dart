import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';

/// Handwritten stub (no Mocktail) mirroring the spec's "tests override with a
/// stub authenticator" instruction. Stateful so a test can flip the availability
/// or the authenticate result between cases.
class _StubBiometricAuthenticator implements BiometricAuthenticator {
  _StubBiometricAuthenticator({
    this.availability = const BiometricAvailability.available(supportedBiometrics: {}),
    this.authenticateResult = true,
  });

  BiometricAvailability availability;
  bool authenticateResult;

  @override
  Future<BiometricAvailability> checkAvailability() async => availability;

  @override
  Future<bool> authenticate({required String localizedReason}) async => authenticateResult;
}

Future<ProviderContainer> _buildContainer(_StubBiometricAuthenticator authenticator) async {
  final container = ProviderContainer(
    overrides: [biometricAuthenticatorProvider.overrideWithValue(authenticator)],
  );
  addTearDown(container.dispose);
  // Keep the controller subscribed so watched-provider invalidations rebuild
  // it eagerly across the availability resolution.
  container.listen(biometricUnlockControllerProvider, (_, _) {}, fireImmediately: true);
  // Resolve the OS availability future before reading the lock state so the
  // controller is past its conservative loading gate.
  await container.read(biometricAvailabilityProvider.future);
  return container;
}

void main() {
  group('BiometricUnlockController', () {
    test('reports locked when the OS reports biometric available', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(
          availability: const BiometricAvailability.available(
            supportedBiometrics: {BiometricKind.face},
          ),
        ),
      );

      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockLocked>());
    });

    test('reports unavailable when the OS reports no usable biometric', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(
          availability: const BiometricAvailability.unavailable(
            reason: BiometricUnavailableReason.notEnrolled,
          ),
        ),
      );

      expect(
        container.read(biometricUnlockControllerProvider),
        isA<BiometricLockUnavailable>(),
      );
    });

    test('a successful authenticate flips locked -> unlocked and returns true', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(),
      );

      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockLocked>());

      final result = await container
          .read(biometricUnlockControllerProvider.notifier)
          .authenticate(localizedReason: 'Unlock');

      expect(result, isTrue);
      // The redirect reads this state: unlocked clears the gate to /lock.
      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockUnlocked>());
    });

    test('a failed authenticate stays locked (never fakes success)', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(authenticateResult: false),
      );

      final result = await container
          .read(biometricUnlockControllerProvider.notifier)
          .authenticate(localizedReason: 'Unlock');

      expect(result, isFalse);
      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockLocked>());
    });

    test('authenticate on an unavailable subsystem is a no-op failure', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(
          availability: const BiometricAvailability.unavailable(),
        ),
      );

      final result = await container
          .read(biometricUnlockControllerProvider.notifier)
          .authenticate(localizedReason: 'Unlock');

      expect(result, isFalse);
      expect(
        container.read(biometricUnlockControllerProvider),
        isA<BiometricLockUnavailable>(),
      );
    });

    test('relock flips unlocked back to locked (lifecycle hook seam)', () async {
      final container = await _buildContainer(
        _StubBiometricAuthenticator(),
      );
      final notifier = container.read(biometricUnlockControllerProvider.notifier);
      await notifier.authenticate(localizedReason: 'Unlock');
      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockUnlocked>());

      notifier.relock();
      expect(container.read(biometricUnlockControllerProvider), isA<BiometricLockLocked>());
    });

    test('unavailable must NOT read as locked (redirect must not loop)', () async {
      // The C5 redirect pattern-matches on `locked`. A device with no usable
      // biometric reports unavailable, which must not be treated as locked —
      // otherwise the user would loop into a prompt that can never succeed.
      final container = await _buildContainer(
        _StubBiometricAuthenticator(
          availability: const BiometricAvailability.unavailable(),
        ),
      );
      final state = container.read(biometricUnlockControllerProvider);
      expect(state, isA<BiometricLockUnavailable>());
      expect(state is BiometricLockLocked, isFalse);
    });
  });
}
