import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_presentation_state.freezed.dart';

/// Deterministic states supported by the Register screen and development gallery.
enum RegisterPresentationStatus {
  idle,
  focused,
  invalid,
  submitting,
  fieldFailure,
  globalFailure,
  success,
}

/// Immutable, screen-specific fixture data for Register.
@freezed
class RegisterPresentationState with _$RegisterPresentationState {
  const RegisterPresentationState({
    this.status = RegisterPresentationStatus.idle,
  });

  const RegisterPresentationState.invalid() : status = RegisterPresentationStatus.invalid;

  const RegisterPresentationState.focused() : status = RegisterPresentationStatus.focused;

  const RegisterPresentationState.submitting() : status = RegisterPresentationStatus.submitting;

  const RegisterPresentationState.fieldFailure() : status = RegisterPresentationStatus.fieldFailure;

  const RegisterPresentationState.globalFailure()
    : status = RegisterPresentationStatus.globalFailure;

  const RegisterPresentationState.success() : status = RegisterPresentationStatus.success;

  @override
  final RegisterPresentationStatus status;
}
