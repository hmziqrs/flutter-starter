import 'dart:math';

import 'package:starter/features/auth/auth_attempt_tracker.dart' show cooldownSecondsFor;

/// Shared read-only lockout policy for state objects that expose a
/// [lockedUntil] timestamp.
///
/// Centralizes the `isLockedAt` / `lockedSecondsAt` getters that were
/// previously duplicated between `AttemptState` and `PasscodeState`. The
/// cooldown table and `cooldownSecondsFor` helper remain centralized in
/// `auth_attempt_tracker.dart`; this mixin only consumes the latter.
mixin VerificationLockoutPolicy {
  /// Wall-clock instant after which verification is allowed again, or `null`
  /// when no lockout is in effect. Implementations (e.g. Freezed state
  /// classes) satisfy this via their `lockedUntil` field.
  DateTime? get lockedUntil;

  /// Whether verification is blocked at [now].
  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

  /// Whole seconds remaining in the lockout at [now], clamped at `0`.
  int lockedSecondsAt(DateTime now) {
    final until = lockedUntil;
    if (until == null) {
      return 0;
    }
    return max(0, until.difference(now).inSeconds);
  }
}

/// Pure helper returning the lockout cooldown, in seconds, that should apply
/// after [attempts] total failures, resolved against the centralized
/// `attemptCooldownSeconds` table via [cooldownSecondsFor].
///
/// [now] is threaded through so callers keep wall-clock time explicit when
/// assembling the resulting `lockedUntil` timestamp; it is not consulted by
/// the table lookup itself.
int computeLockout(int attempts, DateTime now) => cooldownSecondsFor(attempts);
