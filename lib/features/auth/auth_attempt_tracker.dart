/// Exponential per-identifier lockout schedule for repeated failed sign-in
/// attempts.
///
/// This is a **UX / defense-in-depth control only — NOT a security boundary.**
/// Client-side throttling is trivially bypassed (clear the prefs key, swap the
/// device, replay against the server directly). The authoritative gate is
/// server-side (e.g. the mfa-otp test server returns `429 locked`); this local
/// complement keeps the UX honest about a lockout the server already imposed
/// and slows down casual abuse. It must never be presented to a forker as the
/// real enforcement.
///
/// The schedule is a single `const` table: the cooldown in seconds applied when
/// the running failure count reaches each index. Index `0` is the rest state
/// (no failures), index `1` the first failure, and so on; entries past the end
/// clamp to the final value. The default table
/// `[0, 0, 30, 60, 300, 900]` grants two free attempts, then escalates
/// 30s → 60s → 5m → 15m. Change the table in one place — there are no magic
/// numbers at call sites.
///
/// Identifiers (typically an email or phone) are normalized and FNV-1a hashed
/// before they touch the backing map so the raw PII value is never stored as a
/// key, never reaches logs, and never leaks via heap inspection. The hash is
/// non-cryptographic and deterministic; it is for PII hygiene, not security.
///
/// Three consumers — the login page, the OTP page in this feature, and the
/// future pin-autolock feature — share this one pure-Dart class via a direct
/// feature-local import (no `shared/` bucket is warranted for a pure-Dart
/// primitive with designated consumers; see contracts.md C3).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cooldown seconds applied by each failure (1-indexed).
///
/// `table[0]` is the cooldown imposed by the 1st failure, `table[1]` by the
/// 2nd, and so on; counts past the last index clamp to the final entry. With
/// the default `[0, 0, 30, 60, 300, 900]`, the first two failures are free
/// and the third locks for 30s, escalating to 60s → 5m → 15m. The leading-zero
/// count matches [freeAttemptsBeforeLockout] so call sites stay literal-free.
const List<int> attemptCooldownSeconds = [0, 0, 30, 60, 300, 900];

/// Number of failed attempts allowed before the first lockout. Equal to the
/// count of leading zero entries in [attemptCooldownSeconds] — the table is the
/// source of truth and this constant mirrors it for readability at call sites.
const int freeAttemptsBeforeLockout = 2;

/// Lockout seconds for [attemptCooldownSeconds] entries past the table. Kept as
/// a `const` so [AttemptState.nextCooldownSeconds] never needs an `if`/clamp
/// branch in callers.
int get _maxCooldownSeconds => attemptCooldownSeconds.last;

/// Snapshot of the local rate-limit state for one identifier.
///
/// Immutable and value-equal so it can flow through Riverpod unchanged. All
/// derived fields ([attemptsRemaining], [nextCooldownSeconds]) are computed by
/// the tracker at write time using the const cooldown table, so consumers
/// never repeat the schedule arithmetic.
///
/// `lockedUntil` is the absolute wall-clock expiry of the active lockout (or
/// `null` when the identifier is not locked). It is **not** normalized on read:
/// once [lockedUntil] has passed, [isLockedAt] returns `false` but [attempts]
/// and [attemptsRemaining] keep their values so a follow-up failure still
/// escalates per the schedule. Only [AttemptTracker.recordSuccess] clears the
/// record.
@immutable
final class AttemptState {
  /// Creates an immutable snapshot. Construction is feature-internal (the
  /// tracker is the only caller in production); tests construct directly to
  /// exercise the dev-gallery / pinned fixtures.
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

  /// Total failed attempts recorded for this identifier since the last
  /// [AttemptTracker.recordSuccess]. Never resets on lockout expiry — only on
  /// success.
  final int attempts;

  /// Absolute wall-clock time the active lockout expires, or `null` when the
  /// identifier is not locked. Historical: stays set after expiry so a new
  /// failure re-locks immediately at the next schedule step.
  final DateTime? lockedUntil;

  /// Failed attempts the user may still make before the next lockout kicks in.
  /// Zero once [attempts] has reached [freeAttemptsBeforeLockout]; stays zero
  /// after a lockout expires (the schedule escalates rather than forgiving).
  final int attemptsRemaining;

  /// Lockout seconds the *next* failure will impose. Drives the
  /// "too many attempts" copy and lets the UI warn before the lock lands.
  final int nextCooldownSeconds;

  /// Whether the lock is still active at [now]. `false` once [lockedUntil] has
  /// passed (or was always `null`).
  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

  /// Whole seconds left in the active lockout at [now], or `0` when unlocked.
  /// Clamped to non-negative so the countdown text never shows a negative value.
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttemptState &&
            attempts == other.attempts &&
            lockedUntil == other.lockedUntil &&
            attemptsRemaining == other.attemptsRemaining &&
            nextCooldownSeconds == other.nextCooldownSeconds;
  }

  @override
  int get hashCode => Object.hash(attempts, lockedUntil, attemptsRemaining, nextCooldownSeconds);
}

/// Local per-identifier attempt counter and lockout scheduler.
///
/// Pure-Dart and synchronous so it can be reasoned about under `FakeAsync` and
/// shared across login, OTP, and future PIN-autolock surfaces without a
/// per-screen dependency. The default [InMemoryAttemptTracker] is constructed
/// at the composition root; a future persisted variant may layer on
/// `SecureStore` (never `SettingsStore` — plaintext prefs would let a user wipe
/// their own lockout). The persistence choice is injected, never hard-coded.
///
/// Implementations must not throw for ordinary use; the methods are
/// synchronous and best-effort. Identifiers are normalized and hashed by the
/// implementation so the raw value never reaches the backing store.
abstract interface class AttemptTracker {
  /// Records one failed attempt for [identifier] and returns the new state.
  ///
  /// Escalates the lockout per [attemptCooldownSeconds]: the cooldown at the
  /// new attempt count is applied when non-zero, otherwise [AttemptState] is
  /// returned unlocked. The returned state is what the caller renders.
  AttemptState recordFailure(String identifier);

  /// Clears the record for [identifier]. Called on a successful authentication
  /// so a user who eventually types the right value is not one typo away from
  /// a lockout.
  void recordSuccess(String identifier);

  /// Returns the current state for [identifier], or `null` when no failures
  /// have been recorded. Read-only — never mutates the record.
  AttemptState? read(String identifier);
}

/// Deterministic in-memory [AttemptTracker].
///
/// The no-backend production default (a local lockout is authoritative for the
/// local UX — there is no `common.notConnected` path; see the feature spec).
/// Reset on relaunch, which is acceptable for a UX-only complement. Test
/// suites and the dev-gallery inject a fresh instance per group; production
/// constructs one at the composition root.
///
/// Pass a `now` override in tests to assert `lockedUntil` without `FakeAsync`;
/// production omits it and reads `DateTime.now()`.
final class InMemoryAttemptTracker implements AttemptTracker {
  InMemoryAttemptTracker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, AttemptState> _states = {};

  /// Read-only snapshot of every hashed identifier → state entry. Used by
  /// tests to assert schedule escalation; never exposed past the tracker in
  /// production.
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

/// Lockout seconds the schedule imposes for the [attemptCount]-th failure
/// (1-indexed: pass the running failure count after the increment). Values
/// `<= 0` return `0` (no failure recorded yet); counts past the table tail
/// clamp to the final entry so the 7th failure stays at the max cooldown
/// rather than throwing.
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
/// phone never sits in a map key, a prefs row, or a log line.
///
/// Non-cryptographic and deliberately stable: it is for PII hygiene, NOT a
/// security control. Lower-casing and trimming first means `User@Example.com`
/// and `user@example.com ` share a bucket.
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
/// composition root with a fresh [InMemoryAttemptTracker]; throws until wired
/// (mirrors `settingsStoreProvider` / `secureStoreProvider`). Tests override
/// with a fresh in-memory instance per group.
final attemptTrackerProvider = Provider<AttemptTracker>(
  (ref) => throw StateError('AttemptTracker must be overridden at the composition root.'),
);
