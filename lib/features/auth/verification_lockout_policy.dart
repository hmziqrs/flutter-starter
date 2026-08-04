import 'dart:math';

import 'package:starter/features/auth/auth_attempt_tracker.dart' show cooldownSecondsFor;

mixin VerificationLockoutPolicy {
  DateTime? get lockedUntil;

  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

  int lockedSecondsAt(DateTime now) {
    final until = lockedUntil;
    if (until == null) {
      return 0;
    }
    return max(0, until.difference(now).inSeconds);
  }
}

int computeLockout(int attempts, DateTime now) => cooldownSecondsFor(attempts);
