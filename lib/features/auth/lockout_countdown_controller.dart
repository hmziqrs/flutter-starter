import 'dart:async';

import 'package:flutter/foundation.dart';

/// Owns the per-second lockout countdown shared by the auth pages.
///
/// Reproduces the byte-identical countdown loop previously inlined in the login
/// and OTP pages: a [Timer.periodic] that decrements once a second, guards every
/// tick against disposal, and self-cancels the moment the remaining seconds
/// reach zero. Pages seed the value via [syncFrom] (typically from
/// `presentation.lockedSeconds`) and read [remainingSeconds] / [value] to
/// render.
class LockoutCountdownController extends ValueNotifier<int> {
  /// Creates a controller starting at zero remaining seconds.
  LockoutCountdownController() : super(0);

  Timer? _timer;
  bool _disposed = false;

  /// The remaining locked seconds, i.e. the current [value].
  int get remainingSeconds => value;

  /// Resets the countdown to [seconds] and (re)starts the per-second tick.
  ///
  /// Cancels any in-flight timer first, so this is safe to call from
  /// `initState` and from `didUpdateWidget` when the fixture seconds change. A
  /// non-positive value leaves the controller at zero with no timer running,
  /// matching the prior `_startLockoutCountdownIfNeeded` early return.
  void syncFrom(int seconds) {
    _timer?.cancel();
    value = seconds < 0 ? 0 : seconds;
    if (value <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    // Guard mirrors the prior `if (!mounted)` check: once disposed, never
    // mutate value (which would throw on a disposed ValueNotifier).
    if (_disposed) return;
    if (value > 0) value -= 1;
    if (value <= 0) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposed = true;
    super.dispose();
  }
}
