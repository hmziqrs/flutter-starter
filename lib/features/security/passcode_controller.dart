/// Local passcode credential store + brute-force lockout state (pin-autolock).
///
/// Backend-free per spec: all hashing, verification, and lockout bookkeeping are
/// local. The passcode hash + salt live in `SecureStore` (tamper-resistant
/// keychain); the brute-force counter is persisted alongside them in
/// `SecureStore` (never `SettingsStore`, which is plaintext and would let a
/// user wipe their own lockout). The lockout **schedule** is reused verbatim
/// from auth-ratelimit (`freeAttemptsBeforeLockout` + `cooldownSecondsFor`) so
/// there is a single canonical escalation table for every challenge surface.
///
/// Like the AttemptTracker itself, the local lockout is a **UX / defense-in-
/// depth control, not a security boundary** — the authoritative gate is the
/// salted hash. The counter slows casual abuse and keeps the UX honest about a
/// lockout; it must never be presented as the real enforcement.
///
/// The raw passcode is never stored and never logged. The controller never puts
/// the cleartext into a context map or a log line; the `LogRedactor`'s
/// `passcode=` assignment regex is the belt-and-suspenders backstop.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

/// Why a [PasscodeController.verify] call was rejected, when it was. Exhaustive
/// `switch` required at every call site (the page renders each case distinctly).
enum PasscodeVerifyResult {
  /// The hash matched. The controller has disarmed the challenge and cleared
  /// the brute-force counter; the caller navigates forward.
  success,

  /// The hash did not match. `attemptsRemaining` (possibly zero) reflects the
  /// new count; the page re-arms for the next attempt or shows the lockout.
  incorrect,

  /// An active brute-force lockout refuses the attempt before it is hashed.
  /// `lockedUntil` is in the future; the page shows the countdown.
  lockedOut,

  /// No passcode is set, so there is nothing to verify against. The caller
  /// treats this as "no gate" rather than a failure.
  notConfigured,
}

/// Immutable snapshot of the local passcode subsystem.
///
/// Fields mirror the feature spec exactly:
/// - [enabled] — the passcode gate is **armed** (a challenge is required right
///   now). Set on cold start when a hash exists, armed by `AutoLockController`
///   on background-return / idle-timeout, and cleared by a successful `verify`.
///   This is the transient "locked" flag for the passcode subsystem; the user's
///   on/off preference lives in `SettingsState.passcodeEnabled`.
/// - [isSet] — a salted hash exists in `SecureStore` (a passcode has been
///   configured). Sticky until [PasscodeController.disable] clears it.
/// - [attemptsRemaining] — free attempts left before the next lockout step.
/// - [lockedUntil] — absolute wall-clock expiry of the active brute-force
///   lockout, or `null` when not locked out.
///
/// [requiresChallenge] is the single predicate the C5 redirect reads (passcode
/// last in the precedence chain): a shell-tab destination is sent to the
/// passcode entry route only when a hash exists, the gate is armed, and no
/// brute-force lockout is active. The `lockedUntil == null` term keeps a user
/// who is mid-lockout from being redirected away from the entry page they are
/// already on (the entry page is a hard gate — no navigation away until
/// verified — so a non-null `lockedUntil` there just drives the countdown UI).
@immutable
final class PasscodeState {
  const PasscodeState({
    required this.enabled,
    required this.isSet,
    required this.attemptsRemaining,
    required this.lockedUntil,
    this.totalFailures = 0,
  }) : assert(totalFailures >= 0, 'totalFailures must not be negative.');

  /// State for a device with no passcode configured.
  const PasscodeState.absent()
    : enabled = false,
      isSet = false,
      attemptsRemaining = freeAttemptsBeforeLockout,
      lockedUntil = null,
      totalFailures = 0;

  final bool enabled;
  final bool isSet;
  final int attemptsRemaining;
  final DateTime? lockedUntil;

  /// Monotonic count of consecutive failed verifies since the last successful
  /// verify (the schedule index). Unlike [attemptsRemaining] (which clamps at
  /// 0), this counter only ever resets on a successful verify, so the
  /// auth-ratelimit cooldown table escalates 30s -> 60s -> 5m -> 15m across
  /// repeated failures even after a lockout expires. Mirrors the shared
  /// `AttemptTracker`'s monotonic `attempts` field.
  final int totalFailures;

  /// The redirect predicate (passcode, last in the C5 precedence chain).
  bool get requiresChallenge => isSet && enabled && lockedUntil == null;

  /// `true` only while the brute-force lockout is still in the future at [now].
  /// Once [lockedUntil] has passed the lockout is expired (the next attempt is
  /// accepted) but [attemptsRemaining] keeps its value so a fresh failure still
  /// escalates per the schedule.
  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

  /// Whole seconds left in the active lockout at [now], clamped to non-negative.
  int lockedSecondsAt(DateTime now) {
    final until = lockedUntil;
    if (until == null) return 0;
    return max(0, until.difference(now).inSeconds);
  }

  PasscodeState copyWith({
    bool? enabled,
    bool? isSet,
    int? attemptsRemaining,
    DateTime? lockedUntil,
    int? totalFailures,
    bool clearLockedUntil = false,
  }) {
    return PasscodeState(
      enabled: enabled ?? this.enabled,
      isSet: isSet ?? this.isSet,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
      totalFailures: totalFailures ?? this.totalFailures,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PasscodeState &&
            enabled == other.enabled &&
            isSet == other.isSet &&
            attemptsRemaining == other.attemptsRemaining &&
            lockedUntil == other.lockedUntil &&
            totalFailures == other.totalFailures;
  }

  @override
  int get hashCode => Object.hash(enabled, isSet, attemptsRemaining, lockedUntil, totalFailures);
}

/// Handwritten Riverpod seed for the cold-start [PasscodeState]. Overridden at
/// the composition root with the hydrated snapshot so the redirect reads a
/// ready value on the first frame (mirrors `initialSettingsProvider`). The
/// controller hydrates from [SecureStore] when this is not overridden.
final initialPasscodeProvider = Provider<PasscodeState>(
  (ref) => const PasscodeState.absent(),
);

/// Handwritten Riverpod `NotifierProvider` over the passcode subsystem state.
///
/// Methods mirror the feature spec: `setPasscode` / `changePasscode` /
/// `disable` / `verify`, plus `arm` (called by `AutoLockController` on
/// background-return / idle-timeout). No codegen. Overridden at the App
/// `ProviderScope` through `AppDependencies` only when a test needs a fixed
/// seed; production hydrates from `SecureStore` in `build`.
final passcodeControllerProvider = NotifierProvider<PasscodeController, PasscodeState>(
  PasscodeController.new,
);

// The class is intentionally non-`final` so the dev-gallery can pin a fixed
// state via a gallery-only subclass (mirrors `BiometricUnlockController`).
class PasscodeController extends Notifier<PasscodeState> {
  /// SecureStore keys. All four live in the keychain (never plaintext prefs)
  /// so the brute-force counter is tamper-resistant.
  static const saltKey = 'security.passcode.salt';
  static const hashKey = 'security.passcode.hash';
  static const attemptsKey = 'security.passcode.attempts_remaining';
  static const lockedUntilKey = 'security.passcode.locked_until';
  static const totalFailuresKey = 'security.passcode.total_failures';

  SecureStore get _store => ref.read(secureStoreProvider);
  PasscodeHasher get _hasher => ref.read(passcodeHasherProvider);

  @override
  PasscodeState build() {
    // Hydrate from SecureStore. The seed (initialPasscodeProvider) is the
    // composition-root shortcut for tests; otherwise read the keychain so the
    // redirect observes the real configured state on the first frame.
    final seeded = ref.watch(initialPasscodeProvider);
    if (seeded != const PasscodeState.absent()) {
      return seeded;
    }
    // Fire-and-forget hydration: read the keychain and adopt the result. The
    // absent default keeps the redirect permissive until the async read resolves
    // (a passcode that is genuinely unset stays absent; a configured one arms
    // on the next frame). Mirrors how the biometric controller holds its
    // conservative gate only while its availability check is pending.
    unawaited(_hydrate());
    return const PasscodeState.absent();
  }

  Future<void> _hydrate() async {
    try {
      final hash = await _store.read(hashKey);
      if (hash == null || hash.isEmpty) {
        return;
      }
      final attemptsRemaining = _parseAttempts(await _store.read(attemptsKey));
      final lockedUntil = _parseTimestamp(await _store.read(lockedUntilKey));
      final totalFailures = _parseTotalFailures(
        await _store.read(totalFailuresKey),
        attemptsRemaining: attemptsRemaining,
        lockedUntil: lockedUntil,
      );
      // Cold-start re-challenge: a configured passcode arms the gate on every
      // fresh ProviderContainer (every app launch). Within a session, a freshly
      // set passcode stays disarmed (build() ran before setPasscode), so the
      // user is not challenged immediately after setup.
      state = PasscodeState(
        enabled: true,
        isSet: true,
        attemptsRemaining: attemptsRemaining,
        lockedUntil: lockedUntil,
        totalFailures: totalFailures,
      );
    } on SecureStoreException {
      // A keychain read failure degrades to the absent default (no gate) rather
      // than trapping the user out of the app. The hash is the authoritative
      // gate; if it cannot be read, there is nothing honest to challenge with.
    }
  }

  /// Configures a new passcode. Generates a fresh salt, stores the salted hash,
  /// and leaves the gate **disarmed** within this session (the user just chose
  /// the value; challenging them immediately would be poor UX). The next cold
  // start arms via [_hydrate]. Persists the cleared brute-force counter so a
  /// freshly set passcode starts with the full free-attempt budget.
  Future<void> setPasscode(String pin) async {
    final salt = _hasher.generateSalt();
    final hash = _hasher.saltAndHash(pin, salt);
    await _writeAll(salt: salt, hash: hash, attemptsRemaining: freeAttemptsBeforeLockout);
    state = const PasscodeState(
      enabled: false,
      isSet: true,
      attemptsRemaining: freeAttemptsBeforeLockout,
      lockedUntil: null,
    );
  }

  /// Returns true only when [oldPin] verifies against the stored hash before
  /// [newPin] replaces it. A wrong old passcode consumes a brute-force attempt
  /// (delegated to [verify]); a locked-out state refuses the change.
  Future<bool> changePasscode({required String oldPin, required String newPin}) async {
    final result = await verify(oldPin);
    if (result != PasscodeVerifyResult.success) {
      return false;
    }
    await setPasscode(newPin);
    return true;
  }

  /// Removes the salt, hash, and brute-force counter from [SecureStore] and
  /// disarms the gate. The user opted out; subsequent cold starts stay absent.
  Future<void> disable() async {
    await _deleteAll();
    state = const PasscodeState.absent();
  }

  /// Arms the gate (challenge required). Called by `AutoLockController` on
  /// background-return and idle-timeout events. No-op when no passcode is set
  /// (there is nothing to challenge with).
  void arm() {
    if (!state.isSet) return;
    if (state.enabled) return;
    state = state.copyWith(enabled: true);
  }

  /// Attempts to unlock the gate with [pin]. See [PasscodeVerifyResult] for the
  /// exhaustive outcomes. On success the gate is disarmed and the brute-force
  /// counter is cleared; the caller (the page) navigates forward and calls
  /// `autoLockControllerProvider.notifier.unlock()` so the AUTOLOCK block of the
  /// redirect also clears. The raw [pin] is never stored or logged.
  Future<PasscodeVerifyResult> verify(String pin) async {
    if (!state.isSet) return PasscodeVerifyResult.notConfigured;
    if (state.isLockedAt(DateTime.now())) return PasscodeVerifyResult.lockedOut;

    final storedHash = await _readHash();
    if (storedHash == null) {
      // The hydrated state believed a hash existed but the keychain has none
      // (cleared out-of-band). Treat as not-configured rather than failing the
      // attempt — there is nothing to verify against.
      state = const PasscodeState.absent();
      return PasscodeVerifyResult.notConfigured;
    }
    final salt = await _store.read(saltKey);
    if (salt == null) {
      state = const PasscodeState.absent();
      return PasscodeVerifyResult.notConfigured;
    }

    if (constantTimeEquals(_hasher.saltAndHash(pin, salt), storedHash)) {
      await _resetAttempts();
      state = const PasscodeState(
        enabled: false,
        isSet: true,
        attemptsRemaining: freeAttemptsBeforeLockout,
        lockedUntil: null,
      );
      return PasscodeVerifyResult.success;
    }

    await _recordFailure();
    return PasscodeVerifyResult.incorrect;
  }

  Future<void> _recordFailure() async {
    // Reuse the auth-ratelimit schedule (single canonical escalation table) via
    // the MONOTONIC running failure count. The count is 1-indexed (this failure
    // is the Nth); cooldownSecondsFor maps it to 0/0/30/60/300/900. Crucially,
    // the index is NOT re-derived from attemptsRemaining — that field clamps at
    // 0 once the free budget is spent, so deriving from it would cap the index
    // at freeAttemptsBeforeLockout+1 forever and freeze the cooldown at the
    // first lockout tier (30s) for every subsequent failure. The monotonic
    // counter only resets on a successful verify (mirrors the shared
    // AttemptTracker), so a brute-forcer who never succeeds faces the full
    // 30s -> 60s -> 5m -> 15m escalation across repeated lockout cycles.
    final attempts = state.totalFailures + 1;
    final cooldown = cooldownSecondsFor(attempts);
    final now = DateTime.now();
    final lockedUntil = cooldown == 0 ? null : now.add(Duration(seconds: cooldown));
    final attemptsRemaining = max(0, freeAttemptsBeforeLockout - attempts);
    state = state.copyWith(
      totalFailures: attempts,
      attemptsRemaining: attemptsRemaining,
      lockedUntil: lockedUntil,
    );
    await _writeAttempts(
      attemptsRemaining: attemptsRemaining,
      lockedUntil: lockedUntil,
      totalFailures: attempts,
    );
  }

  Future<void> _resetAttempts() async {
    try {
      await _store.write(attemptsKey, freeAttemptsBeforeLockout.toString());
      await _store.delete(lockedUntilKey);
      await _store.delete(totalFailuresKey);
    } on SecureStoreException {
      // Persistence failure does not roll back an unlock — the hash matched and
      // the gate is disarmed in-memory; a stale persisted counter only means the
      // next cold start shows a stale countdown that clears on the first verify.
    }
  }

  Future<String?> _readHash() async {
    try {
      return await _store.read(hashKey);
    } on SecureStoreException {
      return null;
    }
  }

  Future<void> _writeAll({
    required String salt,
    required String hash,
    required int attemptsRemaining,
  }) async {
    try {
      await Future.wait<void>([
        _store.write(saltKey, salt),
        _store.write(hashKey, hash),
        _store.write(attemptsKey, attemptsRemaining.toString()),
        // A fresh passcode has no active lockout and no failure history; clear
        // any stale values.
        _store.delete(lockedUntilKey),
        _store.delete(totalFailuresKey),
      ]);
    } on SecureStoreException {
      // Re-throw as a typed failure so the page surfaces an honest error rather
      // than silently dropping the credential. The in-memory state is NOT
      // updated on persistence failure (setPasscode callers await this).
      rethrow;
    }
  }

  Future<void> _writeAttempts({
    required int attemptsRemaining,
    required DateTime? lockedUntil,
    required int totalFailures,
  }) async {
    try {
      await Future.wait<void>([
        _store.write(attemptsKey, attemptsRemaining.toString()),
        _store.write(totalFailuresKey, totalFailures.toString()),
        switch (lockedUntil) {
          final DateTime expiry => _store.write(lockedUntilKey, expiry.toIso8601String()),
          null => _store.delete(lockedUntilKey),
        },
      ]);
    } on SecureStoreException {
      // Best-effort persistence of the UX counter; the in-memory state is the
      // source of truth for the current session.
    }
  }

  Future<void> _deleteAll() async {
    try {
      await Future.wait<void>([
        _store.delete(saltKey),
        _store.delete(hashKey),
        _store.delete(attemptsKey),
        _store.delete(lockedUntilKey),
        _store.delete(totalFailuresKey),
      ]);
    } on SecureStoreException {
      // Best-effort: a failed delete still disarms in-memory so the user is not
      // trapped. A stale hash left in the keychain is harmless without the gate.
    }
  }

  static int _parseAttempts(String? saved) {
    final parsed = int.tryParse(saved ?? '');
    if (parsed == null || parsed < 0 || parsed > freeAttemptsBeforeLockout) {
      return freeAttemptsBeforeLockout;
    }
    return parsed;
  }

  /// Parses the monotonic failure count. For legacy data written before the
  /// counter existed (or a fresh install), reconcile from [attemptsRemaining]
  /// so a cold start that lands mid-lockout still escalates on the next failure
  /// rather than resetting the schedule to the first tier.
  static int _parseTotalFailures(
    String? saved, {
    required int attemptsRemaining,
    DateTime? lockedUntil,
  }) {
    final parsed = int.tryParse(saved ?? '');
    if (parsed != null && parsed >= 0) {
      return parsed;
    }
    final implied = freeAttemptsBeforeLockout - attemptsRemaining;
    if (implied > 0) {
      return implied;
    }
    // A persisted lockout with no recorded count implies the free budget was
    // spent; seed with at least the first lockout index so escalation resumes.
    return lockedUntil != null ? freeAttemptsBeforeLockout + 1 : 0;
  }

  static DateTime? _parseTimestamp(String? saved) {
    if (saved == null || saved.isEmpty) return null;
    return DateTime.tryParse(saved);
  }

  /// Constant-time string comparison so passcode verification does not leak the
  /// hash length or a prefix via timing. Both operands are fixed-length hex
  /// digests from the same hasher, so the lengths always match in practice; the
  /// guard keeps the comparison honest if a future hasher changes the format.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
