import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/security/auto_lock_controller.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

void main() {
  group('AutoLockController', () {
    ProviderContainer buildContainer({required int delaySeconds, required bool lockOnBackground}) {
      final fresh = ProviderContainer(
        overrides: [
          secureStoreProvider.overrideWithValue(InMemorySecureStore()),
          passcodeHasherProvider.overrideWithValue(const CryptoPasscodeHasher()),
          autoLockDelaySecondsProvider.overrideWithValue(delaySeconds),
          lockOnBackgroundProvider.overrideWithValue(lockOnBackground),
        ],
      );
      addTearDown(fresh.dispose);
      fresh.listen(autoLockControllerProvider, (_, _) {}, fireImmediately: true);
      return fresh;
    }

    test('starts unlocked when idle locking is disabled', () {
      final container = buildContainer(delaySeconds: 0, lockOnBackground: false);
      expect(container.read(autoLockControllerProvider).locked, isFalse);
    });

    test('idle timer past autoLockDelaySeconds arms the lock', () {
      fakeAsync((async) {
        final container = buildContainer(delaySeconds: 30, lockOnBackground: false);
        expect(container.read(autoLockControllerProvider).locked, isFalse);

        async.elapse(const Duration(seconds: 29));
        expect(container.read(autoLockControllerProvider).locked, isFalse);

        async.elapse(const Duration(seconds: 2));
        final state = container.read(autoLockControllerProvider);
        expect(state.locked, isTrue);
        expect(state.lockedReason, AutoLockReason.idleTimeout);
      });
    });

    test('a resumed lifecycle with lockOnBackground arms the lock', () {
      final container = buildContainer(delaySeconds: 0, lockOnBackground: true);
      expect(container.read(autoLockControllerProvider).locked, isFalse);

      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      expect(container.read(autoLockControllerProvider).locked, isFalse);

      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);
      final state = container.read(autoLockControllerProvider);
      expect(state.locked, isTrue);
      expect(state.lockedReason, AutoLockReason.backgroundReturn);
    });

    test('a resumed lifecycle does NOT arm when lockOnBackground is off', () {
      final container = buildContainer(delaySeconds: 0, lockOnBackground: false);
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.paused);
      container.read(appLifecyclePhaseProvider.notifier).transitionTo(AppLifecycleState.resumed);
      expect(container.read(autoLockControllerProvider).locked, isFalse);
    });

    test('unlock clears the lock', () {
      fakeAsync((async) {
        final container = buildContainer(delaySeconds: 5, lockOnBackground: false);
        async.elapse(const Duration(seconds: 6));
        expect(container.read(autoLockControllerProvider).locked, isTrue);

        container.read(autoLockControllerProvider.notifier).unlock();
        expect(container.read(autoLockControllerProvider).locked, isFalse);
      });
    });

    test('extend postpones the idle lockout', () {
      fakeAsync((async) {
        final container = buildContainer(delaySeconds: 10, lockOnBackground: false);
        async.elapse(const Duration(seconds: 7));
        container.read(autoLockControllerProvider.notifier).extend();
        async.elapse(const Duration(seconds: 7));
        expect(container.read(autoLockControllerProvider).locked, isFalse);
        async.elapse(const Duration(seconds: 4));
        expect(container.read(autoLockControllerProvider).locked, isTrue);
      });
    });
  });
}
