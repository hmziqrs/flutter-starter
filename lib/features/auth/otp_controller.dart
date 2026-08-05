import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_session.dart';

part 'otp_controller.freezed.dart';

typedef OtpControllerKey = ({OtpPurpose purpose, String identifier});

@freezed
abstract class OtpControllerState with _$OtpControllerState {
  @Assert('remainingSeconds >= 0', 'remainingSeconds must not be negative.')
  @Assert('attemptsRemaining >= 0', 'attemptsRemaining must not be negative.')
  const factory OtpControllerState({
    @Default(OtpPresentationState()) OtpPresentationState presentation,
    @Default(0) int remainingSeconds,
    @Default(0) int attemptsRemaining,
    @Default(false) bool isExpired,
    AuthAuthenticated? session,
  }) = _OtpControllerState;

  const OtpControllerState._();

  bool get isLocked => presentation.status == OtpPresentationStatus.locked;

  bool get isBusy =>
      presentation.status == OtpPresentationStatus.submitting ||
      presentation.status == OtpPresentationStatus.resending;
}

// ignore: specify_nonobvious_property_types, inferred Riverpod family type
final otpControllerProvider =
    NotifierProvider.family<OtpController, OtpControllerState, OtpControllerKey>(
      OtpController.new,
    );

final class OtpController extends Notifier<OtpControllerState> {
  OtpController(this.key);

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

  Future<bool> verify(String code) async {
    if (state.isBusy || state.isLocked) return false;
    state = state.copyWith(presentation: const OtpPresentationState.submitting());
    try {
      final result = await _repository.verify(identifier: key.identifier, code: code);
      switch (result.outcome) {
        case OtpVerifyOutcome.valid:
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
          return _applyFailure();
      }
    } on OtpRepositoryException {
      state = state.copyWith(presentation: const OtpPresentationState.globalFailure());
      return false;
    }
  }

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

  int _freeAttemptsNow() {
    final recorded = _tracker.read(key.identifier);
    if (recorded == null) return freeAttemptsBeforeLockout;
    return math.max(0, recorded.attemptsRemaining);
  }
}
