import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// Family key for [otpControllerProvider]: `(purpose, identifier)` resolves to
/// the same controller instance, keeping a registration OTP and an MFA OTP for
/// the same identifier independent.
typedef OtpControllerKey = ({OtpPurpose purpose, String identifier});

/// Immutable runtime state surfaced by [OtpController] to the OTP page.
///
/// Composes the fixture-friendly [OtpPresentationState] with the live,
/// controller-owned fields a static fixture cannot carry: [remainingSeconds]
/// (live expiry countdown), [attemptsRemaining] (read from the shared
/// [AttemptTracker]), and [isExpired].
@immutable
final class OtpControllerState {
  const OtpControllerState({
    this.presentation = const OtpPresentationState(),
    this.remainingSeconds = 0,
    this.attemptsRemaining = 0,
    this.isExpired = false,
    this.session,
  }) : assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.'),
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.');

  final OtpPresentationState presentation;
  final int remainingSeconds;
  final int attemptsRemaining;
  final bool isExpired;

  /// The session a registration-purpose verify issued inline; `null` for
  /// every other outcome/purpose. The registration OTP page publishes this via
  /// `SessionController.establish` before navigating home.
  final AuthAuthenticated? session;

  /// `true` while the shared tracker has locked this identifier out.
  bool get isLocked => presentation.status == OtpPresentationStatus.locked;

  /// `true` while a network call is in flight (issue / verify / resend).
  bool get isBusy =>
      presentation.status == OtpPresentationStatus.submitting ||
      presentation.status == OtpPresentationStatus.resending;

  OtpControllerState copyWith({
    OtpPresentationState? presentation,
    int? remainingSeconds,
    int? attemptsRemaining,
    bool? isExpired,
    AuthAuthenticated? session,
  }) {
    return OtpControllerState(
      presentation: presentation ?? this.presentation,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      attemptsRemaining: attemptsRemaining ?? this.attemptsRemaining,
      isExpired: isExpired ?? this.isExpired,
      session: session ?? this.session,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OtpControllerState &&
            presentation == other.presentation &&
            remainingSeconds == other.remainingSeconds &&
            attemptsRemaining == other.attemptsRemaining &&
            isExpired == other.isExpired &&
            session == other.session;
  }

  @override
  int get hashCode =>
      Object.hash(presentation, remainingSeconds, attemptsRemaining, isExpired, session);
}

/// Handwritten Riverpod family [NotifierProvider] over [OtpControllerState].
///
/// One controller per `(OtpPurpose, identifier)`. Owns the expiry `Timer` and
/// submit/resend transitions; reuses the shared [AttemptTracker] so the OTP
/// and sign-in lockout are one schedule. Countdown ticks read `clock.now()`
/// (package:clock) so tests stay deterministic under `FakeAsync` —
/// `DateTime.now()` ignores the fake clock.
// The family builder returns a private `NotifierProviderFamily<...>` type not
// part of flutter_riverpod's public API, so the top-level type is inferred.
// ignore: specify_nonobvious_property_types
final otpControllerProvider =
    NotifierProvider.family<OtpController, OtpControllerState, OtpControllerKey>(
      OtpController.new,
    );

final class OtpController extends Notifier<OtpControllerState> {
  OtpController(this.key);

  /// The `(purpose, identifier)` this instance owns.
  final OtpControllerKey key;

  Timer? _countdown;
  int _remaining = 0;

  OtpRepository get _repository => ref.read(otpRepositoryProvider);
  AttemptTracker get _tracker => ref.read(attemptTrackerProvider);

  @override
  OtpControllerState build() {
    ref.onDispose(() => _countdown?.cancel());
    return OtpControllerState(attemptsRemaining: _freeAttemptsNow());
  }

  /// Requests a fresh code from the backend and starts the expiry countdown.
  /// On [OtpRepositoryException] the state becomes `globalFailure` — never a
  /// faked issued code.
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

  /// Verifies [code] and drives the typed transition. Returns whether the
  /// code was valid. An `invalid`/`locked` outcome records a tracker failure;
  /// a locked schedule surfaces `locked` with the tracker's cooldown seconds.
  Future<bool> verify(String code) async {
    if (state.isBusy || state.isLocked) return false;
    state = state.copyWith(presentation: const OtpPresentationState.submitting());
    try {
      final result = await _repository.verify(identifier: key.identifier, code: code);
      switch (result.outcome) {
        case OtpVerifyOutcome.valid:
          // Clear the tracker on success so a prior typo is not one failure
          // away from a lockout.
          _tracker.recordSuccess(key.identifier);
          _countdown?.cancel();
          state = state.copyWith(
            presentation: const OtpPresentationState.success(),
            remainingSeconds: 0,
            attemptsRemaining: _freeAttemptsNow(),
            isExpired: false,
            session: result.session,
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
          // Server-side 429 agrees with the client cooldown.
          return _applyFailure();
      }
    } on OtpRepositoryException {
      state = state.copyWith(presentation: const OtpPresentationState.globalFailure());
      return false;
    }
  }

  /// Resends the code and restarts the countdown from the refreshed expiry.
  /// Returns `true` on success; on [OtpRepositoryException] the state becomes
  /// `globalFailure` — never a faked "code sent".
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

  /// Records a tracker failure and maps the result to `locked` or `invalid`.
  /// Always returns `false`.
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

  /// (Re)starts the expiry countdown from [expiresAt]. Reaching zero flips the
  /// state to `expired` and cancels the timer.
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

  /// Free attempts left before the next lockout, read from the shared tracker.
  int _freeAttemptsNow() {
    final recorded = _tracker.read(key.identifier);
    if (recorded == null) return freeAttemptsBeforeLockout;
    return math.max(0, recorded.attemptsRemaining);
  }
}
