import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_presentation_state.freezed.dart';

enum LoginPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
  locked,
}

@freezed
class LoginPresentationState with _$LoginPresentationState {
  const LoginPresentationState({
    this.status = LoginPresentationStatus.idle,
    this.successMessage,
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
  }) : assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  const LoginPresentationState.invalid()
    : status = LoginPresentationStatus.invalid,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.focused()
    : status = LoginPresentationStatus.focused,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.submitting()
    : status = LoginPresentationStatus.submitting,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.fieldFailure()
    : status = LoginPresentationStatus.fieldFailure,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.globalFailure()
    : status = LoginPresentationStatus.globalFailure,
      successMessage = null,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.success({this.successMessage})
    : status = LoginPresentationStatus.success,
      attemptsRemaining = 0,
      lockedSeconds = 0;

  const LoginPresentationState.locked({
    this.attemptsRemaining = 0,
    this.lockedSeconds = 0,
  }) : status = LoginPresentationStatus.locked,
       successMessage = null,
       assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),
       assert(lockedSeconds >= 0, 'lockedSeconds must not be negative.');

  @override
  final LoginPresentationStatus status;
  @override
  final String? successMessage;

  @override
  final int attemptsRemaining;

  @override
  final int lockedSeconds;
}
