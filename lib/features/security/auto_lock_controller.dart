/// Session auto-lock timing (pin-autolock).
///
/// Owns the wall-clock idle [Timer] and the background→foreground re-lock. It
/// does **not** register its own `WidgetsBindingObserver` — it `ref.watch`es
/// `appLifecyclePhaseProvider` (owned by lifecycle-observer) for the background
/// →foreground edge, preserving the single-observer model. On a lock event
/// (idle timeout, background return, or manual arm) it sets [AutoLockState]
/// locked and arms the passcode gate via `PasscodeController.arm` so the C5
/// redirect's passcode predicate re-evaluates and sends the user to the entry
/// route. A successful passcode verify clears the lock through `unlock`.
///
/// The idle delay and the background-return toggle reach this controller
/// through `autoLockDelaySecondsProvider` and `lockOnBackgroundProvider`. These
/// default to "idle locking disabled" so the feature is inert until the
/// composition root wires them to `SettingsState.autoLockDelaySeconds` /
/// `SettingsState.lockOnBackground` (see the feature manifest's settingsEdits).
/// Decoupling the read from the settings internal layout keeps this file
/// analyzable standalone and gives the integrator a single override seam.
///
/// The idle timer is wall-clock, not animation-driven, so `disableAnimationsOf`
/// does not pause it — but any countdown UI driven by this state still respects
/// the motion guard at the call site.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';

/// Why the session was re-locked. Exhaustive `switch` required at every call
/// site (UI copy and diagnostics branch on the reason).
enum AutoLockReason {
  /// The idle [Timer] elapsed past the configured delay.
  idleTimeout,

  /// The app returned to the foreground and background-lock is enabled.
  backgroundReturn,

  /// An explicit caller armed the lock (e.g. a "lock now" action).
  manual,
}

/// Immutable snapshot of the session auto-lock state.
///
/// [locked] is the single signal the composition-root redirect consults (via
/// the AUTOLOCK precedence block) to decide whether a protected destination
/// must re-challenge. [lockedReason] carries the why for UI copy and
/// diagnostics; it is `null` while unlocked.
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

/// Idle seconds of inactivity before the session re-locks. `0` (the default)
/// disables idle locking entirely — the controller never arms the idle [Timer]
/// for a non-positive delay. The composition root overrides this to read
/// `SettingsState.autoLockDelaySeconds` so the settings picker drives the
/// timer (see manifest settingsEdits).
final autoLockDelaySecondsProvider = Provider<int>((ref) => 0);

/// Whether returning from background re-locks the session. Default `false`
/// (inert until settings opts in). The composition root overrides this to read
/// `SettingsState.lockOnBackground`.
final lockOnBackgroundProvider = Provider<bool>((ref) => false);

/// Handwritten Riverpod [NotifierProvider] over the session auto-lock state.
///
/// The controller watches [autoLockDelaySecondsProvider] /
/// [lockOnBackgroundProvider] and [appLifecyclePhaseProvider] for the
/// background→foreground edge. It owns the idle [Timer] and re-creates it
/// whenever the delay changes. No codegen; overridden at the App
/// [ProviderScope] only when a test pins a fixed clock or lifecycle.
final autoLockControllerProvider = NotifierProvider<AutoLockController, AutoLockState>(
  AutoLockController.new,
);

final class AutoLockController extends Notifier<AutoLockState> {
  Timer? _idleTimer;

  @override
  AutoLockState build() {
    // Re-evaluate the idle timer whenever the delay setting changes (the
    // override reads SettingsState, so a settings change rebuilds this). A
    // non-positive delay disables idle locking; the timer is cancelled and not
    // re-armed.
    final delaySeconds = ref.watch(autoLockDelaySecondsProvider);
    _resetIdleTimer(delaySeconds: delaySeconds);

    // The idle timer is owned by this controller; on dispose cancel it. Nulling
    // is unnecessary — the whole notifier (and its field) is torn down with the
    // ProviderContainer. Registered before the lifecycle listener so the two
    // `ref.` expression statements are not adjacent (cascade lint).
    ref.onDispose(() => _idleTimer?.cancel());

    // Background -> re-lock. Only the resumed edge after a paused state fires
    // (inactive/hidden are noisy overlays/sheets and must not re-lock). Guarded
    // by [lockOnBackgroundProvider] so a user who opts out is never re-locked on
    // every app switch.
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

  /// Arms the lock: sets [AutoLockState] locked with [reason] and arms the
  /// passcode gate so the redirect re-evaluates. No-op effect on the gate when
  /// no passcode is set (the passcode controller's `arm` refuses; a lock with
  /// no challenge surface is a no-op gate), but [AutoLockState.locked] still
  /// flips for diagnostics. Safe to call repeatedly.
  void arm({AutoLockReason reason = AutoLockReason.manual}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    state = AutoLockState(locked: true, lockedReason: reason);
    ref.read(passcodeControllerProvider.notifier).arm();
  }

  /// Clears the lock (called by the passcode page after a successful verify).
  /// Resets the idle timer so the next idle window starts fresh from the
  /// unlock instant.
  void unlock() {
    state = const AutoLockState.unlocked();
    _resetIdleTimer(delaySeconds: ref.read(autoLockDelaySecondsProvider));
  }

  /// Postpones the idle lockout by restarting the idle timer. Wired to user
  /// interaction (tap / scroll / key) at the composition root; a zero delay
  /// disables idle locking entirely so the timer is never armed.
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
