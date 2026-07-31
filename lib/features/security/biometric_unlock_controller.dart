import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';

final biometricUnlockControllerProvider =
    NotifierProvider<BiometricUnlockController, BiometricLockState>(
      BiometricUnlockController.new,
    );

class BiometricUnlockController extends Notifier<BiometricLockState> {
  @override
  BiometricLockState build() {
    // inactive/hidden are overlay states, not real backgrounding.
    ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
      final wasResumed = previous?.isResumed ?? false;
      if (wasResumed && next.kind == AppLifecycleKind.paused) {
        relock();
      }
    });
    final availability = ref.watch(biometricAvailabilityProvider);
    return availability.when(
      data: (report) =>
          report.canCheck ? const BiometricLockLocked() : const BiometricLockUnavailable(),
      // Hold the lock while availability is pending so cold start never flashes the protected shell.
      loading: () => const BiometricLockLocked(),
      error: (_, _) => const BiometricLockUnavailable(),
    );
  }

  Future<bool> authenticate({required String localizedReason}) async {
    final current = state;
    if (current is BiometricLockUnlocked) return true;
    if (current is! BiometricLockLocked) return false;
    final authenticator = ref.read(biometricAuthenticatorProvider);
    final ok = await authenticator.authenticate(localizedReason: localizedReason);
    if (ok) {
      state = const BiometricLockUnlocked();
    }
    return ok;
  }

  void relock() {
    if (state is BiometricLockUnlocked) {
      state = const BiometricLockLocked();
    }
  }
}
