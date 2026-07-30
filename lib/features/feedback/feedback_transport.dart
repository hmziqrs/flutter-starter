import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';

/// Discrete outcome of a feedback submission. Only [accepted] clears the
/// draft; [unavailable] and [rejected] retain it so the user can retry.
enum FeedbackOutcome {
  /// The backend accepted the report and minted an id.
  accepted,

  /// The backend rejected the report (validation / payload too large).
  rejected,

  /// No backend is configured or reachable; surfaces `common.notConnected`
  /// via the `failed` state, never `accepted`.
  unavailable,
}

/// Typed result of `FeedbackTransport.submit`. [id] is set only on
/// [FeedbackOutcome.accepted]; [cause] is an opaque, already-redacted
/// underlying error forwarded to crash reporting only.
@immutable
final class FeedbackResult {
  const FeedbackResult.accepted(this.id) : outcome = FeedbackOutcome.accepted, cause = null;

  const FeedbackResult.rejected([this.cause]) : outcome = FeedbackOutcome.rejected, id = null;

  const FeedbackResult.unavailable([this.cause]) : outcome = FeedbackOutcome.unavailable, id = null;

  final FeedbackOutcome outcome;

  /// Backend id for the accepted report; `null` otherwise.
  final String? id;

  /// Opaque underlying error for `rejected` / `unavailable`, already
  /// redacted; never a raw email or message body.
  final Object? cause;

  bool get isAccepted => outcome == FeedbackOutcome.accepted;

  @override
  String toString() => 'FeedbackResult(${outcome.name})';
}

/// Typed exception thrown by `FeedbackTransport.submit` for programmer /
/// transport errors that do not map to a typed [FeedbackResult]. The
/// controller maps this to the `failed` presentation state.
final class FeedbackTransportException implements Exception {
  const FeedbackTransportException.notConnected([this.cause])
    : kind = FeedbackFailureKind.notConnected;

  const FeedbackTransportException.invalid([this.cause]) : kind = FeedbackFailureKind.invalid;

  const FeedbackTransportException.unknown([this.cause]) : kind = FeedbackFailureKind.unknown;

  final FeedbackFailureKind kind;

  /// Already-redacted underlying error, if any. Never a raw email or message.
  final Object? cause;

  @override
  String toString() => 'FeedbackTransportException(${kind.name})';
}

/// Reasons a [FeedbackTransport] operation can fail. The Noop default
/// surfaces [notConnected] rather than fabricating an accepted report.
enum FeedbackFailureKind {
  /// No backend is configured or reachable. The Noop default path.
  notConnected,

  /// The submission was rejected as malformed / too large.
  invalid,

  /// A programmer or transport error not classified above.
  unknown,
}

/// The transport payload derived from a validated [FeedbackFormValue]. The
/// optional screenshot fields are populated only by a real transport that
/// captured bytes; the Noop default sends text-only.
@immutable
final class FeedbackSubmission {
  const FeedbackSubmission({
    required this.message,
    required this.appMetadata,
    this.email,
    this.screenshotMime,
    this.screenshotBase64,
  });

  final String message;

  /// Trimmed reply-to address, or `null` when the optional field was blank.
  final String? email;

  final FeedbackAppMetadata appMetadata;

  /// MIME type of the captured screenshot, or `null` when no screenshot was
  /// attached. Pairs with [screenshotBase64].
  final String? screenshotMime;

  /// Base64-encoded screenshot bytes, or `null` when no screenshot was
  /// attached. Pairs with [screenshotMime].
  final String? screenshotBase64;

  /// `true` when a screenshot payload is present.
  bool get hasScreenshot =>
      screenshotMime != null && screenshotBase64 != null && screenshotBase64!.isNotEmpty;

  @override
  String toString() =>
      'FeedbackSubmission(messageLength: ${message.length}, '
      'hasEmail: $email != null, hasScreenshot: $hasScreenshot)';
}

/// The triage state of a previously submitted report, surfaced by the
/// optional `GET /v1/feedback/{id}/status` route. `queued` is the
/// freshly-ingested default; `triaged` means a human has read it. The Noop
/// default reports [FeedbackTriageState.unavailable] (no status without a
/// backend).
enum FeedbackTriageState { queued, triaged, unavailable }

/// The feedback ingest port. No production impl is wired by default: the
/// `NoopFeedbackTransport` default returns `FeedbackResult.unavailable` and
/// never fakes an accepted report. The optional real HTTP adapter implements
/// this against the test-server contract (`POST /v1/feedback` +
/// `GET /v1/feedback/{id}/status`).
abstract interface class FeedbackTransport {
  /// Submits [submission] and returns the typed outcome. Degrades to
  /// `FeedbackResult.unavailable` on failure rather than fabricating an
  /// accepted report.
  Future<FeedbackResult> submit(FeedbackSubmission submission);

  /// Returns the triage state of a previously accepted [id], or
  /// [FeedbackTriageState.unavailable] when no backend is configured / the id
  /// is unknown. Never throws for backend failures.
  Future<FeedbackTriageState> status(String id);
}

/// Handwritten Riverpod handle for the [FeedbackTransport]. Overridden at the
/// App `ProviderScope`; throws until wired. The production default is
/// `NoopFeedbackTransport`; the optional real HTTP adapter is a consumer
/// override only.
final feedbackTransportProvider = Provider<FeedbackTransport>(
  (ref) => throw StateError('FeedbackTransport must be overridden at the composition root.'),
);
