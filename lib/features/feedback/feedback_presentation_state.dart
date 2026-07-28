/// Status of the feedback sheet's lifecycle. The smallest relevant
/// vocabulary (contracts.md shared rules): `idle` is the rest state,
/// `drafting` is "user is composing", `validating` is the synchronous form
/// pass, `submitting` is the transport round-trip, `success` is a confirmed
/// `accepted` result, and `failed` is the honest `unavailable` / transport
/// failure path that surfaces `common.notConnected`.
enum FeedbackPresentationStatus {
  idle,
  drafting,
  validating,
  submitting,
  success,
  failed,
}

/// Immutable, screen-specific presentation state for the feedback sheet.
///
/// Mirrors the auth `*PresentationState` fixtures: a status enum plus named
/// constructors so the dev-gallery `PreviewFrame` can pin
/// `drafting` / `submitting` / `failed` deterministically (feedback spec —
/// dev-gallery fixture). The sheet exhaustive-switches on [status] so strict
/// analysis stays clean (no default arm).
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

  /// `true` while any non-idle action is in flight (validating / submitting).
  /// The sheet gates the submit button + fields on this so a half-submitted
  /// report cannot be re-submitted.
  bool get isBusy =>
      status == FeedbackPresentationStatus.validating ||
      status == FeedbackPresentationStatus.submitting;

  /// `true` once the transport accepted the report. The sheet swaps the form
  /// body for the success copy on this transition.
  bool get isSuccess => status == FeedbackPresentationStatus.success;
}
