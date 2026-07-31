/// Local passcode credential store + brute-force lockout state.
///
/// The salted hash lives in `SecureStore` (never plaintext prefs, so a user
/// can't wipe their own lockout). Lockout schedule is shared with
/// auth-ratelimit (`freeAttemptsBeforeLockout` + `cooldownSecondsFor`). The
/// lockout counter is UX/defense-in-depth only, not the security boundary —
/// the salted hash is authoritative. The raw passcode is never stored or
/// logged.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

part 'passcode_controller.freezed.dart';

/// Outcome of a [PasscodeController.verify] call.
enum PasscodeVerifyResult {
  /// Hash matched; gate disarmed and lockout counter cleared.
  success,

  /// Hash mismatch; `attemptsRemaining` reflects the new count.
  incorrect,

  /// An active lockout refused the attempt before hashing.
  lockedOut,

  /// No passcode configured; treated as "no gate", not a failure.
  notConfigured,
}

/// Immutable snapshot of the local passcode subsystem.
///
/// [enabled] is the transient "armed" flag (challenge required now); the
/// user's on/off preference lives separately in `SettingsState.passcodeEnabled`.
/// [isSet] means a salted hash exists in `SecureStore`.
@Freezed(copyWith: false)
class PasscodeState with _$PasscodeState {
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

  @override
  final bool enabled;
  @override
  final bool isSet;
  @override
  final int attemptsRemaining;
  @override
  final DateTime? lockedUntil;

  /// Monotonic failure count since the last success (the escalation-schedule
  /// index); unlike [attemptsRemaining] it never clamps at 0, so cooldowns keep
  /// escalating 30s -> 60s -> 5m -> 15m across repeated lockouts.
  @override
  final int totalFailures;

  bool get requiresChallenge => isSet && enabled && lockedUntil == null;

  /// True only while the lockout is still in the future; an expired lockout
  /// accepts the next attempt but keeps [attemptsRemaining]'s value.
  bool isLockedAt(DateTime now) {
    final until = lockedUntil;
    return until != null && until.isAfter(now);
  }

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
}

/// Cold-start seed, overridden at the composition root with the hydrated
/// snapshot; the controller hydrates from [SecureStore] otherwise.
final initialPasscodeProvider = Provider<PasscodeState>(
  (ref) => const PasscodeState.absent(),
);

final passcodeControllerProvider = NotifierProvider<PasscodeController, PasscodeState>(
  PasscodeController.new,
);

// Non-`final` so the dev gallery can pin a fixed state via a subclass.
class PasscodeController extends Notifier<PasscodeState> {
  static const saltKey = 'security.passcode.salt';
  static const hashKey = 'security.passcode.hash';
  static const attemptsKey = 'security.passcode.attempts_remaining';
  static const lockedUntilKey = 'security.passcode.locked_until';
  static const totalFailuresKey = 'security.passcode.total_failures';

  SecureStore get _store => ref.read(secureStoreProvider);
  PasscodeHasher get _hasher => ref.read(passcodeHasherProvider);

  @override
  PasscodeState build() {
    final seeded = ref.watch(initialPasscodeProvider);
    if (seeded != const PasscodeState.absent()) {
      return seeded;
    }
    // Fire-and-forget hydration: stay permissive (absent) until the keychain
    // read resolves, then arm on the next frame if a passcode is configured.
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
      // Every fresh launch re-arms a configured passcode; a passcode just set
      // this session stays disarmed until the next cold start.
      state = PasscodeState(
        enabled: true,
        isSet: true,
        attemptsRemaining: attemptsRemaining,
        lockedUntil: lockedUntil,
        totalFailures: totalFailures,
      );
    } on SecureStoreException {
      // Keychain read failure degrades to absent (no gate) rather than
      // trapping the user out of the app.
    }
  }

  /// Stores a fresh salted hash; leaves the gate disarmed for this session
  /// (arms on the next cold start via [_hydrate]) and resets the lockout
  /// counter to the full free-attempt budget.
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

  /// Verifies [oldPin] (consuming a lockout attempt on failure) before storing
  /// [newPin]; refuses while locked out.
  Future<bool> changePasscode({required String oldPin, required String newPin}) async {
    final result = await verify(oldPin);
    if (result != PasscodeVerifyResult.success) {
      return false;
    }
    await setPasscode(newPin);
    return true;
  }

  Future<void> disable() async {
    await _deleteAll();
    state = const PasscodeState.absent();
  }

  /// Arms the gate; called by `AutoLockController` on background-return /
  /// idle-timeout. No-op when no passcode is set.
  void arm() {
    if (!state.isSet) return;
    if (state.enabled) return;
    state = state.copyWith(enabled: true);
  }

  /// Verifies [pin]; the raw value is never stored or logged.
  Future<PasscodeVerifyResult> verify(String pin) async {
    if (!state.isSet) return PasscodeVerifyResult.notConfigured;
    if (state.isLockedAt(DateTime.now())) return PasscodeVerifyResult.lockedOut;

    final storedHash = await _readHash();
    if (storedHash == null) {
      // Hydrated state believed a hash existed but the keychain has none
      // (cleared out-of-band); nothing to verify against.
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
    // Escalation index must come from the monotonic totalFailures, not
    // attemptsRemaining (which clamps at 0 and would freeze the cooldown at
    // the first tier forever).
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
      // Best-effort: the in-memory unlock already happened; a stale persisted
      // counter just clears on the next verify.
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
        _store.delete(lockedUntilKey),
        _store.delete(totalFailuresKey),
      ]);
    } on SecureStoreException {
      // In-memory state is not updated on failure; caller awaits and surfaces it.
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
      // Best-effort: in-memory state is the source of truth for this session.
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
      // Best-effort: in-memory disarm still happens; a stale keychain hash is
      // harmless without the gate.
    }
  }

  static int _parseAttempts(String? saved) {
    final parsed = int.tryParse(saved ?? '');
    if (parsed == null || parsed < 0 || parsed > freeAttemptsBeforeLockout) {
      return freeAttemptsBeforeLockout;
    }
    return parsed;
  }

  /// For legacy data written before this counter existed, reconciles from
  /// [attemptsRemaining] so a cold start mid-lockout still escalates correctly.
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
    return lockedUntil != null ? freeAttemptsBeforeLockout + 1 : 0;
  }

  static DateTime? _parseTimestamp(String? saved) {
    if (saved == null || saved.isEmpty) return null;
    return DateTime.tryParse(saved);
  }

  /// Constant-time compare so verification does not leak hash length/prefix
  /// via timing.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
