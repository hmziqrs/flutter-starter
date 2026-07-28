import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_controller.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/otp_repository.dart';

const String _identifier = 'user@example.com';
const OtpDeliveryChannel _channel = OtpDeliveryChannel.sms;
const ({OtpPurpose purpose, String identifier}) _key = (
  purpose: OtpPurpose.registration,
  identifier: _identifier,
);

OtpIssueResult _issue({required Duration expiresIn}) {
  // Uses clock.now() (overridden by FakeAsync's zone) so the issued expiresAt
  // and the controller's countdown read the SAME fake clock — no sub-second
  // drift between issue and countdown start.
  return OtpIssueResult(
    expiresAt: clock.now().add(expiresIn),
    channel: _channel,
    attemptToken: 'attempt-token',
  );
}

/// Test-only [OtpRepository] fake. Drives the controller's typed transitions
/// deterministically. Lives in the test file (never in lib/) per the no-backend
/// rule — production never fakes a verify result.
class _FakeOtpRepository implements OtpRepository {
  _FakeOtpRepository({this.issueResult, this.verifyResult, this.resendResult});

  OtpIssueResult? issueResult;
  OtpVerifyResult? verifyResult;
  OtpIssueResult? resendResult;
  int issueCalls = 0;
  int verifyCalls = 0;
  int resendCalls = 0;

  @override
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  }) async {
    issueCalls += 1;
    return issueResult ?? _issue(expiresIn: const Duration(seconds: 60));
  }

  @override
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  }) async {
    verifyCalls += 1;
    return verifyResult ?? const OtpVerifyResult.invalid();
  }

  @override
  Future<OtpIssueResult> resend({required String identifier}) async {
    resendCalls += 1;
    return resendResult ?? _issue(expiresIn: const Duration(seconds: 60));
  }
}

/// [_FakeOtpRepository] variant that throws `notConnected` from verify to
/// exercise the controller's no-backend error path on the verify step.
class _ThrowingVerifyRepo extends _FakeOtpRepository {
  _ThrowingVerifyRepo({super.issueResult});

  @override
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  }) async {
    throw const OtpRepositoryException.notConnected();
  }
}

ProviderContainer _container({
  required OtpRepository repository,
  AttemptTracker? tracker,
}) {
  final container = ProviderContainer(
    overrides: [
      otpRepositoryProvider.overrideWithValue(repository),
      attemptTrackerProvider.overrideWithValue(
        tracker ?? InMemoryAttemptTracker(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Fires a Future-returning controller call inside FakeAsync without tripping
/// `discarded_futures`. Completion is driven by `async.flushMicrotasks()` at the
/// call site. Accepts any result type (verify/resend return `bool`).
void fire<T>(Future<T> future) => unawaited(future.then((_) {}));

void main() {
  group('OtpController.requestIssue', () {
    test('starts the expiry countdown at the issued expiresAt', () {
      FakeAsync().run((async) {
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        expect(repo.issueCalls, 1);
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 60);
        expect(container.read(otpControllerProvider(_key)).isExpired, isFalse);
      });
    });

    test('countdown decrements each second and emits expired at zero', () {
      FakeAsync().run((async) {
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 3)),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 3);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 2);
        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 1);
        async.elapse(const Duration(seconds: 1));

        final expired = container.read(otpControllerProvider(_key));
        expect(expired.remainingSeconds, 0);
        expect(expired.isExpired, isTrue);
        expect(expired.presentation.status, OtpPresentationStatus.expired);
      });
    });

    test('a sub-second remainder floors to whole seconds (no negative text)', () {
      FakeAsync().run((async) {
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(milliseconds: 3900)),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        // 3.9s floors to 3; the countdown never shows a negative / fractional.
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 3);
      });
    });
  });

  group('OtpController no-backend (honest unavailable)', () {
    test('requestIssue surfaces globalFailure, never a faked issued code', () {
      FakeAsync().run((async) {
        final container = _container(repository: const InMemoryOtpRepository());
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        final state = container.read(otpControllerProvider(_key));
        expect(state.presentation.status, OtpPresentationStatus.globalFailure);
        expect(state.remainingSeconds, 0);
        expect(state.isExpired, isFalse);
      });
    });
  });

  group('OtpController.verify', () {
    test('valid clears the tracker and emits success', () {
      FakeAsync().run((async) {
        final tracker = InMemoryAttemptTracker()
          ..recordFailure(_identifier); // pre-load so recordSuccess is observable
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.valid(),
        );
        final container = _container(repository: repo, tracker: tracker);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        var valid = false;
        unawaited(
          container.read(otpControllerProvider(_key).notifier).verify('123456').then((v) {
            valid = v;
          }),
        );
        async.flushMicrotasks();

        expect(valid, isTrue);
        expect(
          container.read(otpControllerProvider(_key)).presentation.status,
          OtpPresentationStatus.success,
        );
        expect(tracker.read(_identifier), isNull);
        expect(repo.verifyCalls, 1);
      });
    });

    test('invalid records a failure and surfaces the field error', () {
      FakeAsync().run((async) {
        final tracker = InMemoryAttemptTracker();
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.invalid(),
        );
        final container = _container(repository: repo, tracker: tracker);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        var valid = true;
        unawaited(
          container.read(otpControllerProvider(_key).notifier).verify('000000').then((v) {
            valid = v;
          }),
        );
        async.flushMicrotasks();

        expect(valid, isFalse);
        final state = container.read(otpControllerProvider(_key));
        expect(state.presentation.status, OtpPresentationStatus.invalid);
        expect(state.isLocked, isFalse);
        expect(state.attemptsRemaining, freeAttemptsBeforeLockout - 1);
        expect(tracker.read(_identifier)!.attempts, 1);
      });
    });

    test('repeated invalid attempts escalate to locked and gate submit/resend', () {
      FakeAsync().run((async) {
        final tracker = InMemoryAttemptTracker();
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.invalid(),
        );
        final container = _container(repository: repo, tracker: tracker);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        // freeAttemptsBeforeLockout (2) free, then the next failure locks for
        // the schedule's first non-zero cooldown (30s).
        for (var i = 0; i <= freeAttemptsBeforeLockout; i++) {
          fire(container.read(otpControllerProvider(_key).notifier).verify('000000'));
          async.flushMicrotasks();
        }

        final state = container.read(otpControllerProvider(_key));
        expect(state.presentation.status, OtpPresentationStatus.locked);
        expect(state.isLocked, isTrue);
        // The lockout carries the tracker's cooldown seconds (30) so the page
        // countdown agrees with the auth-ratelimit schedule.
        expect(state.presentation.lockedSeconds, 30);

        // While locked, verify is a no-op that never reaches the repository.
        final callsBefore = repo.verifyCalls;
        var result = true;
        unawaited(
          container.read(otpControllerProvider(_key).notifier).verify('123456').then((v) {
            result = v;
          }),
        );
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(repo.verifyCalls, callsBefore);
      });
    });

    test('server locked result also drives the tracker + locked state', () {
      FakeAsync().run((async) {
        final tracker = InMemoryAttemptTracker();
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.locked(),
        );
        final container = _container(repository: repo, tracker: tracker);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        // Exhaust the free attempts first so the schedule's cooldown applies
        // when the server-locked result records one more failure.
        for (var i = 0; i < freeAttemptsBeforeLockout; i++) {
          tracker.recordFailure(_identifier);
        }
        fire(container.read(otpControllerProvider(_key).notifier).verify('000000'));
        async.flushMicrotasks();

        final state = container.read(otpControllerProvider(_key));
        expect(state.presentation.status, OtpPresentationStatus.locked);
        expect(state.isLocked, isTrue);
      });
    });

    test('expired result cancels the countdown and marks the state expired', () {
      FakeAsync().run((async) {
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.expired(),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 60);

        fire(container.read(otpControllerProvider(_key).notifier).verify('111111'));
        async.flushMicrotasks();

        final state = container.read(otpControllerProvider(_key));
        expect(state.presentation.status, OtpPresentationStatus.expired);
        expect(state.isExpired, isTrue);
        expect(state.remainingSeconds, 0);

        // The countdown timer was cancelled — elapsing time triggers no extra
        // verify calls.
        async.elapse(const Duration(seconds: 30));
        expect(repo.verifyCalls, 1);
      });
    });

    test('a notConnected verify surfaces globalFailure (no faked result)', () {
      FakeAsync().run((async) {
        final repo = _ThrowingVerifyRepo(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();

        fire(container.read(otpControllerProvider(_key).notifier).verify('123456'));
        async.flushMicrotasks();

        expect(
          container.read(otpControllerProvider(_key)).presentation.status,
          OtpPresentationStatus.globalFailure,
        );
      });
    });
  });

  group('OtpController.resend', () {
    test('restarts the countdown from the refreshed expiry', () {
      FakeAsync().run((async) {
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 10)),
          resendResult: _issue(expiresIn: const Duration(seconds: 90)),
        );
        final container = _container(repository: repo);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 10);

        var ok = false;
        unawaited(
          container.read(otpControllerProvider(_key).notifier).resend().then((v) {
            ok = v;
          }),
        );
        async.flushMicrotasks();
        expect(ok, isTrue);
        // The countdown restarted from the resend's refreshed 90s window.
        expect(container.read(otpControllerProvider(_key)).remainingSeconds, 90);
        expect(repo.resendCalls, 1);
      });
    });

    test('resend while locked is a no-op (gated by the lockout)', () {
      FakeAsync().run((async) {
        final tracker = InMemoryAttemptTracker();
        // Force a locked tracker state.
        for (var i = 0; i <= freeAttemptsBeforeLockout; i++) {
          tracker.recordFailure(_identifier);
        }
        final repo = _FakeOtpRepository(
          issueResult: _issue(expiresIn: const Duration(seconds: 60)),
          verifyResult: const OtpVerifyResult.locked(),
        );
        final container = _container(repository: repo, tracker: tracker);
        fire(container.read(otpControllerProvider(_key).notifier).requestIssue());
        async.flushMicrotasks();
        // Drive a locked verify so the controller state reflects the lock.
        fire(container.read(otpControllerProvider(_key).notifier).verify('000000'));
        async.flushMicrotasks();
        expect(container.read(otpControllerProvider(_key)).isLocked, isTrue);

        var ok = true;
        unawaited(
          container.read(otpControllerProvider(_key).notifier).resend().then((v) {
            ok = v;
          }),
        );
        async.flushMicrotasks();
        expect(ok, isFalse);
        expect(repo.resendCalls, 0);
      });
    });
  });

  group('OtpController family isolation', () {
    test('distinct (purpose, identifier) keys keep independent countdowns', () {
      FakeAsync().run((async) {
        // No pre-computed issueResult: the fake computes a fresh expiresAt from
        // clock.now() on EACH issue call, so A (issued at T0) and B (issued at
        // T0+10) get distinct, correctly-stamped expiries.
        final repo = _FakeOtpRepository();
        final container = _container(repository: repo);
        // The record type annotation is required for the family key to resolve
        // (without it the local infers dynamically and the family call breaks).
        // ignore: omit_local_variable_types
        const ({OtpPurpose purpose, String identifier}) a = (
          purpose: OtpPurpose.registration,
          identifier: 'a@b.c',
        );
        // See `a` above: the record annotation is load-bearing for family keying.
        // ignore: omit_local_variable_types
        const ({OtpPurpose purpose, String identifier}) b = (
          purpose: OtpPurpose.passwordReset,
          identifier: 'x@y.z',
        );

        fire(container.read(otpControllerProvider(a).notifier).requestIssue());
        // Elapse 10s on A only — B has no timer running.
        async
          ..flushMicrotasks()
          ..elapse(const Duration(seconds: 10));
        expect(container.read(otpControllerProvider(a)).remainingSeconds, 50);

        fire(container.read(otpControllerProvider(b).notifier).requestIssue());
        async.flushMicrotasks();
        expect(container.read(otpControllerProvider(b)).remainingSeconds, 60);
      });
    });
  });
}
