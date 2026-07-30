import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';

/// Owns only the biometric-subsystem lock status, not the user-facing
/// "biometric unlock enabled" setting — that policy lives in the
/// composition-root redirect, which gates a route to the lock page only when
/// the setting is enabled AND this reports [BiometricLockLocked].
final biometricUnlockControllerProvider =
    NotifierProvider<BiometricUnlockController, BiometricLockState>(
      BiometricUnlockController.new,
    );

class BiometricUnlockController extends Notifier<BiometricLockState> {
  @override
  BiometricLockState build() {
    // Only the resumed -> paused edge relocks; inactive/hidden are noisy
    // overlay states.
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
      // Conservative: hold the lock while availability is pending so a
      // biometric-enabled cold start never flashes the protected shell.
      loading: () => const BiometricLockLocked(),
      error: (_, _) => const BiometricLockUnavailable(),
    );
  }

  /// Presents the OS biometric prompt and returns whether it succeeded;
  /// never fakes success. No-op success if already unlocked, no-op failure
  /// if unavailable.
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

  /// Re-locks if currently unlocked; no-op otherwise.
  void relock() {
    if (state is BiometricLockUnlocked) {
      state = const BiometricLockLocked();
    }
  }
}
