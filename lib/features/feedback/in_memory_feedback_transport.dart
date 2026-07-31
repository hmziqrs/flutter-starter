import 'dart:async';

import 'package:starter/features/feedback/feedback_transport.dart';

final class InMemoryFeedbackTransport implements FeedbackTransport {
  InMemoryFeedbackTransport({
    this.result = const FeedbackResult.accepted('test-id'),
    this.throwException,
    this.delay = Duration.zero,
    this.statusResult = FeedbackTriageState.queued,
  });

  FeedbackResult result;

  FeedbackTransportException? throwException;

  FeedbackTriageState statusResult;

  final Duration delay;

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
