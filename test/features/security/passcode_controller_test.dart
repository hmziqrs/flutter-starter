import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

void main() {
  group('PasscodeController', () {
    late ProviderContainer container;
    late InMemorySecureStore store;

    setUp(() async {
      store = InMemorySecureStore();
      container = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(store),
          passcodeHasherProvider.overrideWithValue(const CryptoPasscodeHasher()),
        ],
      );
      addTearDown(container.dispose);
      // Trigger build so the controller is live, then let the no-op hydrate on
      // an empty store settle before assertions drive it.
      container.listen(passcodeControllerProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });

    test('starts absent with no challenge required', () {
      final state = container.read(passcodeControllerProvider);
      expect(state.isSet, isFalse);
      expect(state.requiresChallenge, isFalse);
    });

    test('setPasscode stores a salted hash and leaves the gate disarmed in-session', () async {
      await container.read(passcodeControllerProvider.notifier).setPasscode('1234');
      final state = container.read(passcodeControllerProvider);
      expect(state.isSet, isTrue);
      // Just-configured: not armed within this session (no cold-start re-challenge).
      expect(state.enabled, isFalse);
      expect(state.requiresChallenge, isFalse);
      // The cleartext is never persisted; only salt + hash are.
      expect(store.snapshot.containsKey(PasscodeController.saltKey), isTrue);
      expect(store.snapshot.containsKey(PasscodeController.hashKey), isTrue);
      for (final entry in store.snapshot.entries) {
        expect(entry.value.contains('1234'), isFalse, reason: 'cleartext must not be persisted');
      }
    });

    test('arm() arms the gate only after a passcode is set', () {
      // No passcode set: arm is a no-op.
      container.read(passcodeControllerProvider.notifier).arm();
      expect(container.read(passcodeControllerProvider).requiresChallenge, isFalse);
    });

    test('verify succeeds for the correct passcode and disarms the armed gate', () async {
      final notifier = container.read(passcodeControllerProvider.notifier);
      await notifier.setPasscode('1234');
      notifier.arm();
      expect(container.read(passcodeControllerProvider).requiresChallenge, isTrue);

      final result = await notifier.verify('1234');
      expect(result, PasscodeVerifyResult.success);
      final state = container.read(passcodeControllerProvider);
      expect(state.enabled, isFalse);
      expect(state.requiresChallenge, isFalse);
      expect(state.attemptsRemaining, freeAttemptsBeforeLockout);
    });

    test('verify returns notConfigured when no passcode is set', () async {
      final result = await container.read(passcodeControllerProvider.notifier).verify('1234');
      expect(result, PasscodeVerifyResult.notConfigured);
    });

    test('repeated wrong verifies decrement attempts then lock out per the schedule', () async {
      final notifier = container.read(passcodeControllerProvider.notifier);
      await notifier.setPasscode('1234');
      notifier.arm();

      // Two free attempts (freeAttemptsBeforeLockout == 2).
      expect(await notifier.verify('0000'), PasscodeVerifyResult.incorrect);
      expect(container.read(passcodeControllerProvider).attemptsRemaining, 1);
      expect(await notifier.verify('0000'), PasscodeVerifyResult.incorrect);
      expect(container.read(passcodeControllerProvider).attemptsRemaining, 0);

      // Third failure imposes the 30s cooldown from the auth-ratelimit table.
      expect(await notifier.verify('0000'), PasscodeVerifyResult.incorrect);
      final lockedState = container.read(passcodeControllerProvider);
      expect(lockedState.lockedUntil, isNotNull);
      expect(lockedState.isLockedAt(DateTime.now()), isTrue);

      // A further attempt while locked is refused before hashing.
      expect(await notifier.verify('0000'), PasscodeVerifyResult.lockedOut);
    });

    test('a correct verify after the lockout expires is accepted', () async {
      final notifier = container.read(passcodeControllerProvider.notifier);
      await notifier.setPasscode('1234');
      notifier.arm();
      // Burn the free attempts and trigger the lockout.
      await notifier.verify('0000');
      await notifier.verify('0000');
      await notifier.verify('0000');
      expect(container.read(passcodeControllerProvider).lockedUntil, isNotNull);

      // Manually expire the lockout by writing a past timestamp, then verify.
      await store.write(
        PasscodeController.lockedUntilKey,
        DateTime.now().subtract(const Duration(seconds: 1)).toIso8601String(),
      );
      // Reload the controller so the expired lockout is observed.
      container
        ..invalidate(passcodeControllerProvider)
        ..listen(passcodeControllerProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(await notifier.verify('1234'), PasscodeVerifyResult.success);
    });

    test('disable clears the credential and returns to absent', () async {
      final notifier = container.read(passcodeControllerProvider.notifier);
      await notifier.setPasscode('1234');
      await notifier.disable();
      final state = container.read(passcodeControllerProvider);
      expect(state.isSet, isFalse);
      expect(state.requiresChallenge, isFalse);
      expect(store.snapshot.containsKey(PasscodeController.hashKey), isFalse);
      expect(store.snapshot.containsKey(PasscodeController.saltKey), isFalse);
    });

    test('changePasscode refuses when the old passcode is wrong', () async {
      final notifier = container.read(passcodeControllerProvider.notifier);
      await notifier.setPasscode('1234');
      final ok = await notifier.changePasscode(oldPin: '0000', newPin: '9999');
      expect(ok, isFalse);
    });

    test('cold-start hydrate with a stored hash arms the gate', () async {
      // Seed the keychain with a real salted hash, then build a fresh container.
      const hasher = CryptoPasscodeHasher();
      final salt = hasher.generateSalt();
      final hash = hasher.saltAndHash('1234', salt);
      final seededStore = InMemorySecureStore(
        seed: {
          PasscodeController.saltKey: salt,
          PasscodeController.hashKey: hash,
        },
      );
      final fresh = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(seededStore),
          passcodeHasherProvider.overrideWithValue(const CryptoPasscodeHasher()),
        ],
      );
      addTearDown(fresh.dispose);
      fresh.listen(passcodeControllerProvider, (_, _) {}, fireImmediately: true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = fresh.read(passcodeControllerProvider);
      expect(state.isSet, isTrue);
      expect(state.enabled, isTrue, reason: 'a stored hash arms on cold start');
      expect(state.requiresChallenge, isTrue);

      // The correct passcode unlocks and disarms.
      expect(
        await fresh.read(passcodeControllerProvider.notifier).verify('1234'),
        PasscodeVerifyResult.success,
      );
      expect(fresh.read(passcodeControllerProvider).requiresChallenge, isFalse);
    });
  });
}
