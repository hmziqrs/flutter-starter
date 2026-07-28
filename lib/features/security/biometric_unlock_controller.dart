import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';

/// Handwritten Riverpod [NotifierProvider] over the biometric lock state.
///
/// The controller owns only the biometric-subsystem lock status — it does not
/// read the user-facing "biometric unlock enabled" setting. That enablement
/// policy is applied in the composition-root redirect (`app_router.dart`'s C5
/// helper): the redirect gates a protected route to the lock page only when the
/// setting is enabled **and** this controller reports [BiometricLockLocked].
/// Keeping the setting read out of the controller avoids a cross-feature import
/// and leaves the policy in the one place that already composes every gate.
///
/// State transitions:
/// - `build` watches [biometricAvailabilityProvider] and reports
///   [BiometricLockLocked] when the OS can authenticate (conservatively also
///   while the check is loading, so there is no flash of an unlocked shell on
///   cold start), [BiometricLockUnavailable] when it cannot or the check
///   fails, and [BiometricLockUnlocked] only after a successful `authenticate`.
/// - `authenticate` presents the OS prompt via the port and flips to
///   [BiometricLockUnlocked] on success; it never fakes success (returns
///   `false` on failure / cancellation / plugin error).
final biometricUnlockControllerProvider =
    NotifierProvider<BiometricUnlockController, BiometricLockState>(
      BiometricUnlockController.new,
    );

class BiometricUnlockController extends Notifier<BiometricLockState> {
  @override
  BiometricLockState build() {
    // Background -> relock (defense-in-depth). When the app transitions from
    // the foreground to paused (backgrounded), re-lock the subsystem so the
    // biometric gate re-evaluates on resume. `inactive` / `hidden` are noisy
    // (overlays, system sheets) and never trigger a relock; only the
    // resumed -> paused edge fires. `relock()` is a no-op when already locked
    // or unavailable, so this listener is safe for every platform.
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
      // Conservative gate: while the OS availability check is pending, hold the
      // lock so a biometric-enabled cold start never flashes the protected
      // shell before the lock page mounts. If the check later resolves to
      // unavailable, the state transitions to [BiometricLockUnavailable].
      loading: () => const BiometricLockLocked(),
      error: (_, _) => const BiometricLockUnavailable(),
    );
  }

  /// Presents the OS biometric prompt with [localizedReason] and returns
  /// whether it succeeded.
  ///
  /// On success the state becomes [BiometricLockUnlocked], which clears the
  /// redirect; the lock page then navigates via its `onUnlocked` callback
  /// (navigation never gates on animation). On failure the state stays
  /// [BiometricLockLocked]; the caller (the page) surfaces the retry. A call
  /// while already [BiometricLockUnlocked] is a no-op success; a call while
  /// [BiometricLockUnavailable] is a no-op failure (the page hides the button
  /// in that state, so this guards against stray invocations).
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

  /// Re-locks the subsystem if it is currently unlocked. Wired to the
  /// app-lifecycle paused edge (background -> relock) in [build]; the cold-start
  /// gate is also established in [build]. No-op when already locked or
  /// unavailable. Also used by tests to drive unlocked -> locked transitions.
  void relock() {
    if (state is BiometricLockUnlocked) {
      state = const BiometricLockLocked();
    }
  }
}
