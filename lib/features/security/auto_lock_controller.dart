library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';

part 'auto_lock_controller.freezed.dart';

enum AutoLockReason { idleTimeout, backgroundReturn, manual }

@Freezed(copyWith: false)
class AutoLockState with _$AutoLockState {
  const AutoLockState({required this.locked, this.lockedReason});

  const AutoLockState.unlocked() : locked = false, lockedReason = null;

  @override
  final bool locked;
  @override
  final AutoLockReason? lockedReason;

  AutoLockState copyWith({bool? locked, AutoLockReason? lockedReason, bool clearReason = false}) {
    return AutoLockState(
      locked: locked ?? this.locked,
      lockedReason: clearReason ? null : (lockedReason ?? this.lockedReason),
    );
  }
}

final autoLockDelaySecondsProvider = Provider<int>((ref) => 0);

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

    // inactive/hidden are overlay states, not real backgrounding.
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

  void arm({AutoLockReason reason = AutoLockReason.manual}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    state = AutoLockState(locked: true, lockedReason: reason);
    ref.read(passcodeControllerProvider.notifier).arm();
  }

  void unlock() {
    state = const AutoLockState.unlocked();
    _resetIdleTimer(delaySeconds: ref.read(autoLockDelaySecondsProvider));
  }

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
