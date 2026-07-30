/// Session auto-lock timing: owns the wall-clock idle [Timer] and the
/// background-return re-lock. Watches `appLifecyclePhaseProvider` rather than
/// registering its own observer, to preserve the single-observer model. On a
/// lock event it sets [AutoLockState] locked and arms the passcode gate via
/// `PasscodeController.arm`; a successful verify clears it via `unlock`.
///
/// The idle timer runs on wall-clock time, not animation-driven, so
/// reduce-motion does not pause it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';

/// Why the session was re-locked.
enum AutoLockReason { idleTimeout, backgroundReturn, manual }

/// Immutable snapshot of the session auto-lock state. [locked] is the signal
/// the composition-root redirect consults to decide whether a protected
/// destination must re-challenge.
@immutable
final class AutoLockState {
  const AutoLockState({required this.locked, this.lockedReason});

  /// Unlocked rest state.
  const AutoLockState.unlocked() : locked = false, lockedReason = null;

  final bool locked;
  final AutoLockReason? lockedReason;

  AutoLockState copyWith({bool? locked, AutoLockReason? lockedReason, bool clearReason = false}) {
    return AutoLockState(
      locked: locked ?? this.locked,
      lockedReason: clearReason ? null : (lockedReason ?? this.lockedReason),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AutoLockState && locked == other.locked && lockedReason == other.lockedReason;
  }

  @override
  int get hashCode => Object.hash(locked, lockedReason);
}

/// Idle seconds before the session re-locks; 0 (default) disables idle
/// locking. The composition root overrides this to read
/// `SettingsState.autoLockDelaySeconds`.
final autoLockDelaySecondsProvider = Provider<int>((ref) => 0);

/// Whether returning from background re-locks the session. Default false;
/// overridden to read `SettingsState.lockOnBackground`.
final lockOnBackgroundProvider = Provider<bool>((ref) => false);

final autoLockControllerProvider = NotifierProvider<AutoLockController, AutoLockState>(
  AutoLockController.new,
);

final class AutoLockController extends Notifier<AutoLockState> {
  Timer? _idleTimer;

  @override
  AutoLockState build() {
    final delaySeconds = ref.watch(autoLockDelaySecondsProvider);
    _resetIdleTimer(delaySeconds: delaySeconds);
    ref.onDispose(() => _idleTimer?.cancel());

    // Only the resumed edge after paused fires (inactive/hidden are noisy
    // overlay states and must not re-lock).
    final lockOnBackground = ref.watch(lockOnBackgroundProvider);
    ref.listen<AppLifecyclePhase>(appLifecyclePhaseProvider, (previous, next) {
      if (!lockOnBackground) return;
      final wasBackground = previous?.kind == AppLifecycleKind.paused;
      if (wasBackground && next.isResumed) {
        arm(reason: AutoLockReason.backgroundReturn);
      }
    });

    return const AutoLockState.unlocked();
  }

  /// Arms the lock and the passcode gate; the gate arm is a no-op without a
  /// configured passcode, but [AutoLockState.locked] still flips.
  void arm({AutoLockReason reason = AutoLockReason.manual}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    state = AutoLockState(locked: true, lockedReason: reason);
    ref.read(passcodeControllerProvider.notifier).arm();
  }

  /// Clears the lock and restarts the idle window from now.
  void unlock() {
    state = const AutoLockState.unlocked();
    _resetIdleTimer(delaySeconds: ref.read(autoLockDelaySecondsProvider));
  }

  /// Restarts the idle timer; wired to user interaction at the composition
  /// root.
  void extend() {
    _resetIdleTimer(delaySeconds: ref.read(autoLockDelaySecondsProvider));
  }

  void _resetIdleTimer({required int delaySeconds}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (delaySeconds <= 0) return;
    _idleTimer = Timer(
      Duration(seconds: delaySeconds),
      () => arm(reason: AutoLockReason.idleTimeout),
    );
  }
}
