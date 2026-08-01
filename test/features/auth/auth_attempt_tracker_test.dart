import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';

void main() {
  group('AttemptState', () {
    test('isLockedAt is false without a lockedUntil', () {
      const state = AttemptState(
        attempts: 0,
        lockedUntil: null,
        attemptsRemaining: freeAttemptsBeforeLockout,
        nextCooldownSeconds: 0,
      );
      expect(state.isLockedAt(DateTime(2026, 7, 27)), isFalse);
      expect(state.lockedSecondsAt(DateTime(2026, 7, 27)), 0);
    });

    test('isLockedAt honors lockedUntil against the supplied clock', () {
      final until = DateTime(2026, 7, 27, 12, 0, 30);
      final state = AttemptState(
        attempts: 3,
        lockedUntil: until,
        attemptsRemaining: 0,
        nextCooldownSeconds: 300,
      );
      expect(state.isLockedAt(until.subtract(const Duration(seconds: 1))), isTrue);
      expect(state.isLockedAt(until), isFalse);
      expect(state.isLockedAt(until.add(const Duration(seconds: 1))), isFalse);
      expect(
        state.lockedSecondsAt(until.subtract(const Duration(seconds: 45))),
        45,
      );
    });

    test('lockedSecondsAt clamps to zero after expiry', () {
      final until = DateTime(2026, 7, 27, 12, 0, 30);
      final state = AttemptState(
        attempts: 3,
        lockedUntil: until,
        attemptsRemaining: 0,
        nextCooldownSeconds: 60,
      );
      expect(
        state.lockedSecondsAt(until.add(const Duration(minutes: 5))),
        0,
      );
    });

    test('value equality covers every field', () {
      final until = DateTime(2026, 7, 27, 12, 0, 30);
      const unlocked = AttemptState(
        attempts: 1,
        lockedUntil: null,
        attemptsRemaining: 1,
        nextCooldownSeconds: 0,
      );
      expect(
        unlocked,
        const AttemptState(
          attempts: 1,
          lockedUntil: null,
          attemptsRemaining: 1,
          nextCooldownSeconds: 0,
        ),
      );
      expect(
        AttemptState(
          attempts: 2,
          lockedUntil: until,
          attemptsRemaining: 0,
          nextCooldownSeconds: 60,
        ),
        AttemptState(
          attempts: 2,
          lockedUntil: until,
          attemptsRemaining: 0,
          nextCooldownSeconds: 60,
        ),
      );
    });
  });

  group('cooldownSecondsFor', () {
    test('mirrors the const schedule exactly (1-indexed by failure)', () {
      expect(cooldownSecondsFor(0), 0);
      expect(cooldownSecondsFor(1), 0);
      expect(cooldownSecondsFor(2), 0);
      expect(cooldownSecondsFor(3), 30);
      expect(cooldownSecondsFor(4), 60);
      expect(cooldownSecondsFor(5), 300);
      expect(cooldownSecondsFor(6), 900);
    });

    test('clamps past the table tail to the max entry', () {
      expect(cooldownSecondsFor(1000), 900);
      expect(cooldownSecondsFor(attemptCooldownSeconds.length + 5), 900);
    });

    test('rejects non-positive counts with zero', () {
      expect(cooldownSecondsFor(-1), 0);
    });
  });

  group('hashIdentifier', () {
    test('normalizes case and surrounding whitespace', () {
      expect(
        hashIdentifier('user@example.com'),
        hashIdentifier('  User@Example.COM '),
      );
    });

    test('produces a stable 8-hex-digit digest', () {
      expect(
        hashIdentifier('user@example.com'),
        matches(RegExp(r'^[0-9a-f]{8}$')),
      );
      expect(
        hashIdentifier('user@example.com'),
        hashIdentifier('user@example.com'),
      );
    });

    test('distinguishes different identifiers', () {
      expect(
        hashIdentifier('a@example.com'),
        isNot(hashIdentifier('b@example.com')),
      );
    });
  });

  group('InMemoryAttemptTracker', () {
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 7, 27, 12);
    });

    InMemoryAttemptTracker buildTracker() => InMemoryAttemptTracker(now: () => now);

    test('read returns null for an unknown identifier', () {
      expect(buildTracker().read('unknown@example.com'), isNull);
    });

    test('recordSuccess on an unknown identifier is a no-op', () {
      final tracker = buildTracker()..recordSuccess('unknown@example.com');
      expect(tracker.snapshot, isEmpty);
    });

    test('escalates the cooldown schedule one failure at a time', () {
      final tracker = buildTracker();
      const identifier = 'person@example.com';

      final first = tracker.recordFailure(identifier);
      expect(first.attempts, 1);
      expect(first.lockedUntil, isNull);
      expect(first.attemptsRemaining, 1);
      expect(first.nextCooldownSeconds, 0);

      final second = tracker.recordFailure(identifier);
      expect(second.attempts, 2);
      expect(second.lockedUntil, isNull);
      expect(second.attemptsRemaining, 0);
      expect(second.nextCooldownSeconds, 30);

      final third = tracker.recordFailure(identifier);
      expect(third.attempts, 3);
      expect(third.attemptsRemaining, 0);
      expect(third.lockedUntil, now.add(const Duration(seconds: 30)));
      expect(third.nextCooldownSeconds, 60);

      final fourth = tracker.recordFailure(identifier);
      expect(fourth.lockedUntil, now.add(const Duration(seconds: 60)));
      expect(fourth.nextCooldownSeconds, 300);
      final fifth = tracker.recordFailure(identifier);
      expect(fifth.lockedUntil, now.add(const Duration(seconds: 300)));
      expect(fifth.nextCooldownSeconds, 900);
      final sixth = tracker.recordFailure(identifier);
      expect(sixth.lockedUntil, now.add(const Duration(seconds: 900)));
      expect(sixth.nextCooldownSeconds, 900);

      final overTheTail = tracker.recordFailure(identifier);
      expect(overTheTail.lockedUntil, now.add(const Duration(seconds: 900)));
      expect(overTheTail.nextCooldownSeconds, 900);
    });

    test('recordSuccess clears the record so the next failure starts over', () {
      final tracker = buildTracker();
      const identifier = 'person@example.com';

      tracker
        ..recordFailure(identifier)
        ..recordFailure(identifier)
        ..recordFailure(identifier)
        ..recordSuccess(identifier);

      expect(tracker.read(identifier), isNull);

      final after = tracker.recordFailure(identifier);
      expect(after.attempts, 1);
      expect(after.attemptsRemaining, 1);
      expect(after.lockedUntil, isNull);
    });

    test('does not reset on read after lockout expiry; the next failure still '
        'escalates', () {
      final tracker = buildTracker();
      const identifier = 'person@example.com';

      tracker
        ..recordFailure(identifier)
        ..recordFailure(identifier)
        ..recordFailure(identifier);

      final locked = tracker.read(identifier)!;
      expect(locked.attempts, 3);
      expect(locked.isLockedAt(now), isTrue);
      expect(
        locked.isLockedAt(now.add(const Duration(seconds: 31))),
        isFalse,
      );

      final after = tracker.recordFailure(identifier);
      expect(after.attempts, 4);
      expect(after.lockedUntil, now.add(const Duration(seconds: 60)));
    });

    test('keys distinct identifiers independently', () {
      final tracker = buildTracker()
        ..recordFailure('a@example.com')
        ..recordFailure('a@example.com')
        ..recordFailure('b@example.com');

      expect(tracker.read('a@example.com')!.attempts, 2);
      expect(tracker.read('b@example.com')!.attempts, 1);
      expect(tracker.read('c@example.com'), isNull);
      expect(tracker.snapshot.length, 2);
    });

    test('case-insensitive identifier collides into one bucket', () {
      final tracker = buildTracker()
        ..recordFailure('User@Example.com')
        ..recordFailure('user@example.com');

      final state = tracker.read('USER@example.com');
      expect(state, isNotNull);
      expect(state!.attempts, 2);
    });

    test('the returned AttemptState is identical to the stored snapshot', () {
      final tracker = buildTracker();
      final state = tracker.recordFailure('person@example.com');
      expect(tracker.read('person@example.com'), state);
    });
  });

  group('attemptTrackerProvider', () {
    test('throws until the composition root overrides it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(attemptTrackerProvider),
        throwsA(
          (Object error) => error.toString().contains('AttemptTracker must be overridden'),
        ),
      );
    });

    test('an overridden InMemoryAttemptTracker is reachable', () {
      final container = ProviderContainer(
        overrides: [
          attemptTrackerProvider.overrideWithValue(InMemoryAttemptTracker()),
        ],
      );
      addTearDown(container.dispose);
      final tracker = container.read(attemptTrackerProvider);
      expect(tracker, isA<InMemoryAttemptTracker>());
      expect(tracker.read('person@example.com'), isNull);
    });
  });
}
