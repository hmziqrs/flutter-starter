import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_presentation_state.freezed.dart';

enum FeedbackPresentationStatus {
  idle,
  drafting,
  validating,
  submitting,
  success,
  failed,
}

@freezed
class FeedbackPresentationState with _$FeedbackPresentationState {
  const FeedbackPresentationState({
    this.status = FeedbackPresentationStatus.idle,
  });

  const FeedbackPresentationState.drafting() : status = FeedbackPresentationStatus.drafting;

  const FeedbackPresentationState.validating() : status = FeedbackPresentationStatus.validating;

  const FeedbackPresentationState.submitting() : status = FeedbackPresentationStatus.submitting;

  const FeedbackPresentationState.success() : status = FeedbackPresentationStatus.success;

  const FeedbackPresentationState.failed() : status = FeedbackPresentationStatus.failed;

  @override
  final FeedbackPresentationStatus status;

  bool get isBusy =>
      status == FeedbackPresentationStatus.validating ||
      status == FeedbackPresentationStatus.submitting;

  bool get isSuccess => status == FeedbackPresentationStatus.success;
}
