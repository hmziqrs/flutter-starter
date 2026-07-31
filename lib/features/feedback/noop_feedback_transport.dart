import 'package:starter/features/feedback/feedback_transport.dart';

final class NoopFeedbackTransport implements FeedbackTransport {
  const NoopFeedbackTransport();

  @override
  Future<FeedbackResult> submit(FeedbackSubmission submission) async =>
      const FeedbackResult.unavailable();

  @override
  Future<FeedbackTriageState> status(String id) async => FeedbackTriageState.unavailable;
}
