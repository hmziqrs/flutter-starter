/// Status of the feedback sheet's lifecycle: `idle` is the rest state,
/// `drafting` is composing, `validating` is the synchronous form pass,
/// `submitting` is the transport round-trip, `success` is a confirmed
/// `accepted` result, and `failed` covers `unavailable` / transport failure
/// (surfaces `common.notConnected`).
enum FeedbackPresentationStatus {
  idle,
  drafting,
  validating,
  submitting,
  success,
  failed,
}

/// Immutable, screen-specific presentation state for the feedback sheet: a
/// status enum plus named constructors so the dev-gallery can pin
/// `drafting` / `submitting` / `failed` deterministically. The sheet
/// exhaustive-switches on [status].
final class FeedbackPresentationState {
  const FeedbackPresentationState({
    this.status = FeedbackPresentationStatus.idle,
  });

  const FeedbackPresentationState.drafting() : status = FeedbackPresentationStatus.drafting;

  const FeedbackPresentationState.validating() : status = FeedbackPresentationStatus.validating;

  const FeedbackPresentationState.submitting() : status = FeedbackPresentationStatus.submitting;

  const FeedbackPresentationState.success() : status = FeedbackPresentationStatus.success;

  const FeedbackPresentationState.failed() : status = FeedbackPresentationStatus.failed;

  final FeedbackPresentationStatus status;

  /// `true` while validating / submitting; gates the submit button + fields.
  bool get isBusy =>
      status == FeedbackPresentationStatus.validating ||
      status == FeedbackPresentationStatus.submitting;

  /// `true` once the transport accepted the report.
  bool get isSuccess => status == FeedbackPresentationStatus.success;
}
