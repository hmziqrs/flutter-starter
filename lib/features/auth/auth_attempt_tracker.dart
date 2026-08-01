import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_attempt_tracker.freezed.dart';

const List<int> attemptCooldownSeconds = [0, 0, 30, 60, 300, 900];

const int freeAttemptsBeforeLockout = 2;

int get _maxCooldownSeconds => attemptCooldownSeconds.last;

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

  @override
  final int attempts;

  @override
  final DateTime? lockedUntil;

  @override
  final int attemptsRemaining;

  @override
  final int nextCooldownSeconds;

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

abstract interface class AttemptTracker {
  AttemptState recordFailure(String identifier);

  void recordSuccess(String identifier);

  AttemptState? read(String identifier);
}

final class InMemoryAttemptTracker implements AttemptTracker {
  InMemoryAttemptTracker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, AttemptState> _states = {};

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

String hashIdentifier(String identifier) {
  final normalized = identifier.trim().toLowerCase();
  var hash = 0x811C9DC5;
  for (final codeUnit in normalized.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

final attemptTrackerProvider = Provider<AttemptTracker>(
  (ref) => throw StateError('AttemptTracker must be overridden at the composition root.'),
);
