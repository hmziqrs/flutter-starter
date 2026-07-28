import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';

/// Discrete outcome of a feedback submission. The controller exhaustive-
/// switches on this (strict-analysis clean — no default arm). Only
/// [accepted] clears the draft; [unavailable] and [rejected] retain it so
/// the user can retry (feedback spec — draft persistence scope note).
enum FeedbackOutcome {
  /// The backend accepted the report and minted an id. Drives the `success`
  /// presentation state and clears the persisted draft.
  accepted,

  /// The backend rejected the report (validation / payload too large). Drives
  /// the `failed` presentation state but the draft is retained for retry.
  rejected,

  /// No backend is configured or reachable. The honest Noop default (C2);
  /// surfaces `common.notConnected` via the `failed` state, never `accepted`.
  unavailable,
}

/// Typed result of `FeedbackTransport.submit`. A handwritten discriminated
/// union over [FeedbackOutcome]; never a `Map` or a `bool`. The optional
/// [id] is set only on [FeedbackOutcome.accepted]; [cause] is an opaque,
/// already-redacted underlying error forwarded to crash reporting only.
@immutable
final class FeedbackResult {
  const FeedbackResult.accepted(this.id) : outcome = FeedbackOutcome.accepted, cause = null;

  const FeedbackResult.rejected([this.cause]) : outcome = FeedbackOutcome.rejected, id = null;

  const FeedbackResult.unavailable([this.cause]) : outcome = FeedbackOutcome.unavailable, id = null;

  final FeedbackOutcome outcome;

  /// Backend id for the accepted report; `null` otherwise.
  final String? id;

  /// Opaque underlying error for `rejected` / `unavailable`. Forwarded to
  /// crash reporting already redacted; never a raw email or message body.
  final Object? cause;

  bool get isAccepted => outcome == FeedbackOutcome.accepted;

  @override
  String toString() => 'FeedbackResult(${outcome.name})';
}

/// Typed exception thrown by `FeedbackTransport.submit` for programmer /
/// transport errors that do not map to a typed [FeedbackResult]. Mirrors
/// `OtpRepositoryException` / `SettingsStoreException`: a typed reason the
/// controller maps to the `failed` presentation state. The optional [cause]
/// is already redacted before it reaches this object.
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

/// Reasons a [FeedbackTransport] operation can fail. Surfaced to the
/// controller through [FeedbackTransportException]; the honest Noop default
/// surfaces [notConnected] rather than fabricating an accepted report (C2).
enum FeedbackFailureKind {
  /// No backend is configured or reachable. The Noop default path.
  notConnected,

  /// The submission was rejected as malformed / too large.
  invalid,

  /// A programmer or transport error not classified above.
  unknown,
}

/// The transport payload derived from a validated [FeedbackFormValue]. A
/// handwritten typed value; never a `Map`. The optional screenshot fields
/// are populated only by a real transport that captured bytes — the Noop
/// default sends text-only and the `includeScreenshot` toggle is inert
/// (feedback spec — screenshot capture needs a real backend note).
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

  /// `true` when a screenshot payload is present. Convenience for the
  /// transport so it can short-circuit the multipart encode path.
  bool get hasScreenshot =>
      screenshotMime != null && screenshotBase64 != null && screenshotBase64!.isNotEmpty;

  @override
  String toString() =>
      'FeedbackSubmission(messageLength: ${message.length}, '
      'hasEmail: $email != null, hasScreenshot: $hasScreenshot)';
}

/// The triage state of a previously submitted report, surfaced by the
/// optional `GET /v1/feedback/{id}/status` route for a future status view
/// (feedback spec — backend & test surface). `queued` is the freshly-ingested
/// default; `triaged` means a human has read it. The Noop default reports
/// [FeedbackTriageState.unavailable] honestly (no status without a backend).
enum FeedbackTriageState { queued, triaged, unavailable }

/// The feedback ingest port.
///
/// Mirrors `OtpRepository` / `VersionGateStore`: `Future`-returning operations
/// throwing a typed [FeedbackTransportException] for programmer errors. **No
/// production impl is wired by default** (the no-backend rule, C2): the
/// `NoopFeedbackTransport` default returns `FeedbackResult.unavailable` and
/// never fakes an accepted report. The optional real HTTP adapter (a
/// consumer-owned adapter constructed only when an endpoint is configured)
/// implements this against the test-server contract (`POST /v1/feedback` +
/// `GET /v1/feedback/{id}/status`).
abstract interface class FeedbackTransport {
  /// Submits [submission] to the feedback backend and returns the typed
  /// outcome. Implementations wrap their backing transport in `try/on Object`
  /// and degrade to `FeedbackResult.unavailable` on failure: a missing backend
  /// must never fabricate an accepted report.
  Future<FeedbackResult> submit(FeedbackSubmission submission);

  /// Returns the triage state of a previously accepted [id], or
  /// [FeedbackTriageState.unavailable] when no backend is configured / the id
  /// is unknown. Never throws for backend failures (mirrors
  /// `VersionGateStore.check`'s degrade-on-failure posture). The Noop default
  /// always returns `unavailable`.
  Future<FeedbackTriageState> status(String id);
}

/// Handwritten Riverpod handle for the [FeedbackTransport]. Overridden at the
/// App `ProviderScope`; throws until wired (mirrors `otpRepositoryProvider` /
/// `settingsStoreProvider`). The production default is `NoopFeedbackTransport`
/// (constructed in `AppDependencies.production`); the optional real HTTP
/// adapter is a consumer override only.
final feedbackTransportProvider = Provider<FeedbackTransport>(
  (ref) => throw StateError('FeedbackTransport must be overridden at the composition root.'),
);
