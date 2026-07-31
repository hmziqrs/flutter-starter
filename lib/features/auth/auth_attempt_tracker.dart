/// Exponential per-identifier lockout schedule for repeated failed sign-in
/// attempts.
///
/// UX / defense-in-depth only — NOT a security boundary (trivially bypassed
/// client-side; the server's own 429 is authoritative). This keeps the UX
/// honest about a lockout the server already imposes.
///
/// Shared by the login page, the OTP page, and any future PIN-autolock
/// feature via a direct feature-local import.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_attempt_tracker.freezed.dart';

/// Cooldown seconds per failure count (1-indexed); counts past the table tail
/// clamp to the final entry. `[0, 0, 30, 60, 300, 900]`: two free attempts,
/// then 30s -> 60s -> 5m -> 15m.
const List<int> attemptCooldownSeconds = [0, 0, 30, 60, 300, 900];

/// Failed attempts allowed before the first lockout (leading-zero count of
/// [attemptCooldownSeconds]).
const int freeAttemptsBeforeLockout = 2;

int get _maxCooldownSeconds => attemptCooldownSeconds.last;

/// Snapshot of the local rate-limit state for one identifier.
///
/// `lockedUntil` is not normalized on read: once it has passed, [isLockedAt]
/// returns `false` but [attempts]/[attemptsRemaining] are unchanged so a
/// follow-up failure keeps escalating. Only [AttemptTracker.recordSuccess]
/// clears the record.
@Freezed(copyWith: false)
class AttemptState with _$AttemptState {
  const AttemptState({
    required this.attempts,
    required this.lockedUntil,
    required this.attemptsRemaining,
    required this.nextCooldownSeconds,
  }) : assert(attempts >= 0, 'attempts must not be negative.'),
       assert(
         attemptsRemaining >= 0,
         'attemptsRemaining must not be negative.',
       ),
       assert(
         nextCooldownSeconds >= 0,
         'nextCooldownSeconds must not be negative.',
       );

  /// Total failed attempts since the last [AttemptTracker.recordSuccess].
  @override
  final int attempts;

  /// Absolute expiry of the active lockout, or `null` when not locked.
  @override
  final DateTime? lockedUntil;

  /// Failed attempts still allowed before the next lockout.
  @override
  final int attemptsRemaining;

  /// Lockout seconds the *next* failure will impose.
  @override
  final int nextCooldownSeconds;

  /// Whether the lock is still active at [now].
  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

  /// Whole seconds left in the active lockout at [now], or `0` when unlocked.
  int lockedSecondsAt(DateTime now) {
    final until = lockedUntil;
    if (until == null) {
      return 0;
    }
    return max(0, until.difference(now).inSeconds);
  }

  AttemptState copyWith({
    int? attempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
    int? attemptsRemaining,
    int? nextCooldownSeconds,
  }) {
    return AttemptState(
      attempts: attempts ?? this.attempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      nextCooldownSeconds: nextCooldownSeconds ?? this.nextCooldownSeconds,
    );
  }
}

/// Local per-identifier attempt counter and lockout scheduler.
///
/// Pure-Dart and synchronous so it works under `FakeAsync`. Identifiers are
/// normalized and hashed by the implementation before touching the backing
/// store.
abstract interface class AttemptTracker {
  /// Records one failed attempt for [identifier] and returns the new state.
  AttemptState recordFailure(String identifier);

  /// Clears the record for [identifier] on a successful authentication.
  void recordSuccess(String identifier);

  /// Returns the current state for [identifier], or `null` if unrecorded.
  AttemptState? read(String identifier);
}

/// Deterministic in-memory [AttemptTracker]. Resets on relaunch, which is
/// acceptable for a UX-only complement.
final class InMemoryAttemptTracker implements AttemptTracker {
  InMemoryAttemptTracker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, AttemptState> _states = {};

  /// Read-only snapshot of every hashed identifier -> state entry (tests only).
  Map<String, AttemptState> get snapshot => Map.unmodifiable(_states);

  @override
  AttemptState recordFailure(String identifier) {
    final key = hashIdentifier(identifier);
    final previous = _states[key];
    final attempts = (previous?.attempts ?? 0) + 1;
    final cooldown = cooldownSecondsFor(attempts);
    final lockedUntil = cooldown == 0 ? null : _now().add(Duration(seconds: cooldown));
    final state = AttemptState(
      attempts: attempts,
      lockedUntil: lockedUntil,
      attemptsRemaining: max(0, freeAttemptsBeforeLockout - attempts),
      nextCooldownSeconds: cooldownSecondsFor(attempts + 1),
    );
    _states[key] = state;
    return state;
  }

  @override
  void recordSuccess(String identifier) {
    _states.remove(hashIdentifier(identifier));
  }

  @override
  AttemptState? read(String identifier) => _states[hashIdentifier(identifier)];
}

/// Lockout seconds for the [attemptCount]-th failure (1-indexed). `<= 0`
/// returns `0`; counts past the table tail clamp to the max cooldown.
int cooldownSecondsFor(int attemptCount) {
  if (attemptCount <= 0) {
    return 0;
  }
  final index = attemptCount - 1;
  if (index >= attemptCooldownSeconds.length) {
    return _maxCooldownSeconds;
  }
  return attemptCooldownSeconds[index];
}

/// Normalizes and hashes [identifier] with FNV-1a (32-bit) so the raw email /
/// phone never sits in a map key or a log line. Non-cryptographic — PII
/// hygiene only, not a security control.
String hashIdentifier(String identifier) {
  final normalized = identifier.trim().toLowerCase();
  var hash = 0x811C9DC5;
  for (final codeUnit in normalized.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Handwritten Riverpod handle for the [AttemptTracker]. Overridden at the
/// composition root; throws until wired.
final attemptTrackerProvider = Provider<AttemptTracker>(
  (ref) => throw StateError('AttemptTracker must be overridden at the composition root.'),
);
