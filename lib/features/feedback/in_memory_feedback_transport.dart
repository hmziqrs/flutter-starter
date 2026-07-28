import 'dart:async';

import 'package:starter/features/feedback/feedback_transport.dart';

/// Deterministic in-memory [FeedbackTransport] for controller / widget tests
/// and the dev-gallery's live accept path.
///
/// Mirrors `InMemorySettingsStore`'s toggle style: a configurable [result] +
/// a recorded [submissions] list. Reassign [result] to drive the controller's
/// success / rejected / unavailable branches without a network; [throwException]
/// forces the controller's typed-exception path. The default returns `accepted`
/// so a test exercising the happy path reads cleanly; flip to `unavailable` to
/// assert the honest no-backend copy.
///
/// Test-only (C2 / C13): never constructed by `AppDependencies.production`,
/// never reaches a release build. Production paths use `NoopFeedbackTransport`
/// (honest unavailable) or the consumer's real HTTP adapter.
final class InMemoryFeedbackTransport implements FeedbackTransport {
  InMemoryFeedbackTransport({
    this.result = const FeedbackResult.accepted('test-id'),
    this.throwException,
    this.delay = Duration.zero,
    this.statusResult = FeedbackTriageState.queued,
  });

  /// The result returned from the next [submit]. Reassign in a test to flip
  /// the controller between `success` / `failed` states mid-flow.
  FeedbackResult result;

  /// When non-null, [submit] throws this exception instead of returning
  /// [result] so the controller's typed-exception path can be exercised.
  FeedbackTransportException? throwException;

  /// Result returned from [status] for any id. Defaults to `queued`.
  FeedbackTriageState statusResult;

  /// Optional delay applied before [submit] resolves so a test can assert the
  /// `submitting` busy state. `Duration.zero` by default (tests rarely need it;
  /// the controller flips to `submitting` synchronously before the await).
  final Duration delay;

  /// Recorded submissions in arrival order. Read-only snapshot; tests assert
  /// `first.message` / `first.email` / `first.appMetadata` after a submit.
  final List<FeedbackSubmission> _submissions = <FeedbackSubmission>[];
  List<FeedbackSubmission> get submissions => List.unmodifiable(_submissions);

  @override
  Future<FeedbackResult> submit(FeedbackSubmission submission) async {
    _submissions.add(submission);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final error = throwException;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<FeedbackTriageState> status(String id) async => statusResult;
}
