import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/shared/errors/repository_exception.dart';

enum FeedbackOutcome {
  accepted,

  rejected,

  unavailable,
}

@immutable
final class FeedbackResult {
  const FeedbackResult.accepted(this.id) : outcome = FeedbackOutcome.accepted, cause = null;

  const FeedbackResult.rejected([this.cause]) : outcome = FeedbackOutcome.rejected, id = null;

  const FeedbackResult.unavailable([this.cause]) : outcome = FeedbackOutcome.unavailable, id = null;

  final FeedbackOutcome outcome;

  final String? id;

  final Object? cause;

  bool get isAccepted => outcome == FeedbackOutcome.accepted;

  @override
  String toString() => 'FeedbackResult(${outcome.name})';
}

final class FeedbackTransportException extends RepositoryException<FeedbackFailureKind> {
  const FeedbackTransportException.notConnected([Object? cause])
    : super(kind: FeedbackFailureKind.notConnected, cause: cause);

  const FeedbackTransportException.invalid([Object? cause])
    : super(kind: FeedbackFailureKind.invalid, cause: cause);

  const FeedbackTransportException.unknown([Object? cause])
    : super(kind: FeedbackFailureKind.unknown, cause: cause);

  @override
  String toString() => describe('FeedbackTransportException');
}

enum FeedbackFailureKind {
  notConnected,

  invalid,

  unknown,
}

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

  final String? email;

  final FeedbackAppMetadata appMetadata;

  final String? screenshotMime;

  final String? screenshotBase64;

  bool get hasScreenshot =>
      screenshotMime != null && screenshotBase64 != null && screenshotBase64!.isNotEmpty;

  @override
  String toString() =>
      'FeedbackSubmission(messageLength: ${message.length}, '
      'hasEmail: $email != null, hasScreenshot: $hasScreenshot)';
}

enum FeedbackTriageState { queued, triaged, unavailable }

abstract interface class FeedbackTransport {
  Future<FeedbackResult> submit(FeedbackSubmission submission);

  Future<FeedbackTriageState> status(String id);
}

final feedbackTransportProvider = Provider<FeedbackTransport>(
  (ref) => throw StateError('FeedbackTransport must be overridden at the composition root.'),
);
