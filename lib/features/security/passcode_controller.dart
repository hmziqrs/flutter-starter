import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/security/passcode_hasher.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';

part 'passcode_controller.freezed.dart';

enum PasscodeVerifyResult {
  success,

  incorrect,

  lockedOut,

  notConfigured,
}

@Freezed(copyWith: false)
class PasscodeState with _$PasscodeState {
  const PasscodeState({
    required this.enabled,
    required this.isSet,
    required this.attemptsRemaining,
    required this.lockedUntil,
    this.totalFailures = 0,
  }) : assert(totalFailures >= 0, 'totalFailures must not be negative.');

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

  @override
  final int totalFailures;

  bool get requiresChallenge => isSet && enabled && lockedUntil == null;

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

final initialPasscodeProvider = Provider<PasscodeState>(
  (ref) => const PasscodeState.absent(),
);

final passcodeControllerProvider = NotifierProvider<PasscodeController, PasscodeState>(
  PasscodeController.new,
);

class PasscodeController extends Notifier<PasscodeState> {
  static const saltKey = 'security.passcode.salt';
  static const hashKey = 'security.passcode.hash';
  static const attemptsKey = 'security.passcode.attempts_remaining';
  static const lockedUntilKey = 'security.passcode.locked_until';
  static const totalFailuresKey = 'security.passcode.total_failures';

  SecureStore get _store => ref.read(secureStoreProvider);
  PasscodeHasher get _hasher => ref.read(passcodeHasherProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  @override
  PasscodeState build() {
    final seeded = ref.watch(initialPasscodeProvider);
    if (seeded != const PasscodeState.absent()) {
      return seeded;
    }
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
      state = PasscodeState(
        enabled: true,
        isSet: true,
        attemptsRemaining: attemptsRemaining,
        lockedUntil: lockedUntil,
        totalFailures: totalFailures,
      );
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning('passcode.hydrate_failed', error: error, stackTrace: stackTrace);
    }
  }

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

  void arm() {
    if (!state.isSet) return;
    if (state.enabled) return;
    state = state.copyWith(enabled: true);
  }

  Future<PasscodeVerifyResult> verify(String pin) async {
    if (!state.isSet) return PasscodeVerifyResult.notConfigured;
    if (state.isLockedAt(DateTime.now())) return PasscodeVerifyResult.lockedOut;

    final storedHash = await _readHash();
    if (storedHash == null) {
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
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning(
        'passcode.reset_attempts_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _readHash() async {
    try {
      return await _store.read(hashKey);
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning('passcode.read_hash_failed', error: error, stackTrace: stackTrace);
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
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning(
        'passcode.write_attempts_failed',
        error: error,
        stackTrace: stackTrace,
      );
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
    } on SecureStoreException catch (error, stackTrace) {
      _logger.warning('passcode.delete_all_failed', error: error, stackTrace: stackTrace);
    }
  }

  static int _parseAttempts(String? saved) {
    final parsed = int.tryParse(saved ?? '');
    if (parsed == null || parsed < 0 || parsed > freeAttemptsBeforeLockout) {
      return freeAttemptsBeforeLockout;
    }
    return parsed;
  }

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

  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
