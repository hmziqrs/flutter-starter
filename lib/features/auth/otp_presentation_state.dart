import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_presentation_state.freezed.dart';

enum OtpPresentationStatus {
  empty,
  partial,
  pastedComplete,
  invalid,
  expired,
  resending,
  submitting,
  globalFailure,
  success,
  locked,
}

/// Immutable, screen-specific fixture data for OTP verification.
@freezed
class OtpPresentationState with _$OtpPresentationState {
  const OtpPresentationState({
    this.status = OtpPresentationStatus.empty,
    this.resendSeconds = 0,
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
    this.remainingSeconds = 0,
  }) : assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.'),
       assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.partial({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.partial,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.pastedComplete({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.pastedComplete,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.invalid({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.invalid,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.expired({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.expired,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.resending({this.remainingSeconds = 0})
    : status = OtpPresentationStatus.resending,
      resendSeconds = 0,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.submitting({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.submitting,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.globalFailure({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.globalFailure,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  const OtpPresentationState.success({this.resendSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.success,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  /// Live expiry countdown fixture, pinned by the dev-gallery/golden so a
  /// deterministic value renders without a Timer. Distinct from
  /// [lockedSeconds] (the lockout cooldown) — never aliased.
  const OtpPresentationState.countdown({this.remainingSeconds = 0})
    : status = OtpPresentationStatus.empty,
      resendSeconds = 0,
      attemptsRemaining = 0,
      lockedSeconds = 0,
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  /// Locked out after too many failed OTP attempts. [lockedSeconds] drives the
  /// live countdown and submit gate; [attemptsRemaining] surfaces the plural.
  const OtpPresentationState.locked({this.lockedSeconds = 0, this.remainingSeconds = 0})
    : status = OtpPresentationStatus.locked,
      resendSeconds = 0,
      attemptsRemaining = 0,
      assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.'),
      assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  @override
  final OtpPresentationStatus status;
  @override
  final int resendSeconds;

  /// Failed attempts the user may still make before the next lockout. Surfaced
  /// via a non-destructive alert while not locked; zero once locked.
  @override
  final int attemptsRemaining;

  /// Whole seconds in the active lockout at construction. The page runs a live
  /// countdown from this value and disables submit while it is positive.
  @override
  final int lockedSeconds;

  /// Whole seconds before the issued code expires (static-fixture field; the
  /// runtime countdown lives on `OtpControllerState.remainingSeconds`).
  @override
  final int remainingSeconds;

  // Placed after the named constructors so the public API reads top-down.
  // ignore: sort_constructors_first
  const OtpPresentationState._({
    required this.status,
    this.resendSeconds = 0,
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
    this.remainingSeconds = 0,
  }) : assert(resendSeconds >= 0, 'resendSeconds must not be negative.'),
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.'),
       assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.');

  /// Returns a copy with `remainingSeconds` overridden. Merges the
  /// controller's live value into the static-fixture presentation.
  OtpPresentationState copyWithRemainingSeconds(int remainingSeconds) {
    return OtpPresentationState._(
      status: status,
      resendSeconds: resendSeconds,
      attemptsRemaining: attemptsRemaining,
      lockedSeconds: lockedSeconds,
      remainingSeconds: remainingSeconds,
    );
  }
}
