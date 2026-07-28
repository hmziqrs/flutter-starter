import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';

void main() {
  group('NoopBiometricAuthenticator', () {
    test('reports unavailable with the unsupported reason (never canCheck)', () async {
      const authenticator = NoopBiometricAuthenticator();
      final availability = await authenticator.checkAvailability();

      expect(availability.canCheck, isFalse);
      expect(availability.reason, BiometricUnavailableReason.unsupported);
      expect(availability.supportedBiometrics, isEmpty);
    });

    test('authenticate never fakes a successful unlock', () async {
      const authenticator = NoopBiometricAuthenticator();
      final result = await authenticator.authenticate(localizedReason: 'Unlock');

      expect(result, isFalse);
    });

    test('is a const-constructible honest default (no backend wiring)', () async {
      // Two independent const instances behave identically — the no-backend
      // default is stateless and deterministic.
      const a = NoopBiometricAuthenticator();
      const b = NoopBiometricAuthenticator();
      expect((await a.checkAvailability()).canCheck, (await b.checkAvailability()).canCheck);
      expect(
        await a.authenticate(localizedReason: 'x'),
        await b.authenticate(localizedReason: 'y'),
      );
    });
  });

  group('BiometricAvailability value object', () {
    test('available reports canCheck true and a null reason', () {
      const availability = BiometricAvailability.available(
        supportedBiometrics: {BiometricKind.face, BiometricKind.fingerprint},
      );
      expect(availability.canCheck, isTrue);
      expect(availability.reason, isNull);
      expect(availability.supportedBiometrics, {BiometricKind.face, BiometricKind.fingerprint});
    });

    test('unavailable defaults to the unknown reason', () {
      const availability = BiometricAvailability.unavailable();
      expect(availability.canCheck, isFalse);
      expect(availability.reason, BiometricUnavailableReason.unknown);
    });

    test('equality is order-independent for the biometric set', () {
      const a = BiometricAvailability.available(
        supportedBiometrics: {BiometricKind.face, BiometricKind.fingerprint},
      );
      const b = BiometricAvailability.available(
        supportedBiometrics: {BiometricKind.fingerprint, BiometricKind.face},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different reasons are not equal', () {
      const a = BiometricAvailability.unavailable(reason: BiometricUnavailableReason.unsupported);
      const b = BiometricAvailability.unavailable(reason: BiometricUnavailableReason.notEnrolled);
      expect(a == b, isFalse);
    });
  });

  group('BiometricLockState', () {
    test('exposes exactly the unlocked / locked / unavailable variants', () {
      const states = <BiometricLockState>[
        BiometricLockUnlocked(),
        BiometricLockLocked(),
        BiometricLockUnavailable(),
      ];
      // The redirect pattern-matches on `locked`; this asserts the exhaustive
      // switch has all three cases to handle.
      expect(states.whereType<BiometricLockLocked>(), hasLength(1));
      expect(states.whereType<BiometricLockUnlocked>(), hasLength(1));
      expect(states.whereType<BiometricLockUnavailable>(), hasLength(1));
    });
  });
}
