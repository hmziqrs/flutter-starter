import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/otp_repository.dart';

/// Family key for [otpControllerProvider]. A record so two calls with the same
/// `(purpose, identifier)` resolve to the same controller instance (Riverpod
/// family equality), and so a registration OTP and an MFA OTP for the same
/// identifier stay independent. The identifier is the raw value the tracker
/// normalizes + hashes internally — it never reaches a log here.
typedef OtpControllerKey = ({OtpPurpose purpose, String identifier});

/// Immutable runtime state surfaced by [OtpController] to the OTP page.
///
/// Composes the fixture-friendly [OtpPresentationState] (status, lockout, resend
/// cooldown — the same type the dev-gallery and goldens pin deterministically)
/// with the live, controller-owned fields a static fixture cannot carry:
///
/// - [remainingSeconds]: the live expiry countdown, decremented by the
///   controller's `Timer.periodic`. Fixtures express a pinned countdown via the
///   described `OtpPresentationState.remainingSeconds`; at runtime this field is
///   the source so the page never starts its own timer.
/// - [attemptsRemaining]: read from the shared [AttemptTracker] so the
///   "attempts remaining" notice stays in lockstep with the lockout schedule
///   (auth-ratelimit owns the schedule; this controller only reads it).
/// - [isExpired]: convenience flag set the moment the countdown hits zero.
@immutable
final class OtpControllerState {
  const OtpControllerState({
    this.presentation = const OtpPresentationState(),
    this.remainingSeconds = 0,
    this.attemptsRemaining = 0,
    this.isExpired = false,
  }) : assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.'),
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.');

  final OtpPresentationState presentation;
  final int remainingSeconds;
  final int attemptsRemaining;
  final bool isExpired;

  /// `true` while the shared tracker has locked this identifier out. Mirrors
  /// the page's existing `_locked` guard so submit / resend stay disabled for
  /// the full cooldown exactly like the static fixture path.
  bool get isLocked => presentation.status == OtpPresentationStatus.locked;

  /// `true` while a network call is in flight (issue / verify / resend). The
  /// page ORs this with its own callback flags to gate the submit button.
  bool get isBusy =>
      presentation.status == OtpPresentationStatus.submitting ||
      presentation.status == OtpPresentationStatus.resending;

  OtpControllerState copyWith({
    OtpPresentationState? presentation,
    int? remainingSeconds,
    int? attemptsRemaining,
    bool? isExpired,
  }) {
    return OtpControllerState(
      presentation: presentation ?? this.presentation,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpControllerState &&
            presentation == other.presentation &&
            remainingSeconds == other.remainingSeconds &&
            attemptsRemaining == other.attemptsRemaining &&
            isExpired == other.isExpired;
  }

  @override
  int get hashCode => Object.hash(presentation, remainingSeconds, attemptsRemaining, isExpired);
}

/// Handwritten Riverpod family [NotifierProvider] over [OtpControllerState].
///
/// One controller per `(OtpPurpose, identifier)`. The controller owns the expiry
/// `Timer` and the submit/resend state transitions; it reuses the shared
/// [AttemptTracker] (auth-ratelimit) for lockout so the OTP cooldown and the
/// sign-in cooldown are one schedule, not two. It does **not** own retry policy
/// — the tracker's const table is the single source.
///
/// The countdown `Timer.periodic` and the expiry derivation read `clock.now()`
/// (package:clock), which is faked under `FakeAsync`'s zone; unit + golden
/// tests therefore assert the countdown without wall-clock flakiness (dart:core
/// `DateTime.now()` ignores the fake clock, so `clock.now()` is load-bearing).
/// Navigation never gates on the timer — the page reads
/// `state` and navigates on the `success` transition.
// The family builder returns a private `NotifierProviderFamily<...>` type that
// is not part of flutter_riverpod's public API, so the top-level type is
// inferred (non-obvious). ignore the annotation lint rather than depend on a
// private symbol.
// ignore: specify_nonobvious_property_types
final otpControllerProvider =
    NotifierProvider.family<OtpController, OtpControllerState, OtpControllerKey>(
      OtpController.new,
    );

final class OtpController extends Notifier<OtpControllerState> {
  OtpController(this.key);

  /// The `(purpose, identifier)` this instance owns. Set by the family
  /// constructor; read in [build] and every transition.
  final OtpControllerKey key;

  Timer? _countdown;
  // Whole seconds remaining in the active code. Decremented by the periodic
  // timer; read by [state] via copyWith. Kept as a field so the timer callback
  // does not recompute from wall-clock on every tick.
  int _remaining = 0;

  OtpRepository get _repository => ref.read(otpRepositoryProvider);
  AttemptTracker get _tracker => ref.read(attemptTrackerProvider);

  @override
  OtpControllerState build() {
    // Cancel the expiry timer if the element is disposed (family eviction or
    // app teardown) so a backgrounded OTP page never fires after dispose.
    ref.onDispose(() => _countdown?.cancel());
    return OtpControllerState(attemptsRemaining: _freeAttemptsNow());
  }

  /// Requests a fresh code from the backend and starts the expiry countdown.
  ///
  /// On [OtpRepositoryException] the state becomes `globalFailure` (which the
  /// page maps to `common.notConnected`) — never a faked issued code. Called by
  /// the page on init for the MFA purpose (and after a successful resend).
  Future<void> requestIssue() async {
    if (state.isBusy) return;
    state = state.copyWith(presentation: const OtpPresentationState.submitting());
    try {
      final result = await _repository.issue(
        purpose: key.purpose,
        identifier: key.identifier,
      );
      _startCountdown(result.expiresAt);
    } on OtpRepositoryException {
      state = state.copyWith(presentation: const OtpPresentationState.globalFailure());
    }
  }

  /// Verifies [code] against the outstanding issue and drives the typed
  /// transition. Returns whether the code was valid (the page navigates on
  /// `true`). Reuses the shared [AttemptTracker]: an `invalid` or `locked`
  /// result records a failure, and if the schedule locks the identifier the
  /// state becomes `locked` with the tracker's cooldown seconds.
  Future<bool> verify(String code) async {
    if (state.isBusy || state.isLocked) return false;
    state = state.copyWith(presentation: const OtpPresentationState.submitting());
    try {
      final result = await _repository.verify(identifier: key.identifier, code: code);
      switch (result.outcome) {
        case OtpVerifyOutcome.valid:
          // A success clears the shared tracker so an eventual typo is not one
          // failure away from a lockout (mirrors login).
          _tracker.recordSuccess(key.identifier);
          _countdown?.cancel();
          state = state.copyWith(
            presentation: const OtpPresentationState.success(),
            remainingSeconds: 0,
            attemptsRemaining: _freeAttemptsNow(),
            isExpired: false,
          );
          return true;
        case OtpVerifyOutcome.invalid:
          return _applyFailure();
        case OtpVerifyOutcome.expired:
          _countdown?.cancel();
          state = state.copyWith(
            presentation: const OtpPresentationState.expired(),
            remainingSeconds: 0,
            isExpired: true,
          );
          return false;
        case OtpVerifyOutcome.locked:
          // Server-side 429 agrees with the client cooldown: record so the
          // schedule and the notice stay in lockstep, then surface locked.
          return _applyFailure();
      }
    } on OtpRepositoryException {
      state = state.copyWith(presentation: const OtpPresentationState.globalFailure());
      return false;
    }
  }

  /// Resends the code and restarts the countdown from the refreshed expiry.
  ///
  /// Returns `true` when the resend + countdown restart succeeded so the page
  /// can clear its resend-cooldown affordance. On [OtpRepositoryException] the
  /// state becomes `globalFailure` — never a faked "code sent".
  Future<bool> resend() async {
    if (state.isBusy || state.isLocked) return false;
    state = state.copyWith(presentation: const OtpPresentationState.resending());
    try {
      final result = await _repository.resend(identifier: key.identifier);
      _startCountdown(result.expiresAt);
      return true;
    } on OtpRepositoryException {
      state = state.copyWith(presentation: const OtpPresentationState.globalFailure());
      return false;
    }
  }

  /// Records a tracker failure and maps the resulting [AttemptState] to either
  /// `locked` (schedule imposed a cooldown) or `invalid` (still within free
  /// attempts). Always returns `false` (never a valid verify).
  bool _applyFailure() {
    final attempt = _tracker.recordFailure(key.identifier);
    final now = clock.now();
    final presentation = attempt.isLockedAt(now)
        ? OtpPresentationState.locked(lockedSeconds: attempt.lockedSecondsAt(now))
        : const OtpPresentationState.invalid();
    state = state.copyWith(
      presentation: presentation,
      attemptsRemaining: math.max(0, attempt.attemptsRemaining),
    );
    return false;
  }

  /// (Re)starts the expiry countdown from [expiresAt]. Each tick decrements
  /// `remainingSeconds`; reaching zero flips the state to `expired` and cancels
  /// the timer. `DateTime.now()` is faked under `FakeAsync`, so the countdown is
  /// deterministic in unit + golden tests.
  void _startCountdown(DateTime expiresAt) {
    _countdown?.cancel();
    final start = expiresAt.difference(clock.now()).inSeconds;
    _remaining = start < 0 ? 0 : start;
    if (_remaining <= 0) {
      state = state.copyWith(
        presentation: const OtpPresentationState.expired(),
        remainingSeconds: 0,
        attemptsRemaining: _freeAttemptsNow(),
        isExpired: true,
      );
      return;
    }
    state = state.copyWith(
      presentation: const OtpPresentationState(),
      remainingSeconds: _remaining,
      attemptsRemaining: _freeAttemptsNow(),
      isExpired: false,
    );
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) _remaining -= 1;
      if (_remaining <= 0) {
        _countdown?.cancel();
        state = state.copyWith(
          presentation: const OtpPresentationState.expired(),
          remainingSeconds: 0,
          isExpired: true,
        );
      } else {
        state = state.copyWith(remainingSeconds: _remaining);
      }
    });
  }

  /// Free attempts the identifier still has before the next lockout, read from
  /// the shared tracker (or the full allowance when nothing is recorded yet).
  int _freeAttemptsNow() {
    final recorded = _tracker.read(key.identifier);
    if (recorded == null) return freeAttemptsBeforeLockout;
    return math.max(0, recorded.attemptsRemaining);
  }
}
