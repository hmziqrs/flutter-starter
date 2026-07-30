import 'package:starter/features/feedback/feedback_transport.dart';

/// Noop [FeedbackTransport] for the no-backend production default. `submit`
/// returns `FeedbackResult.unavailable` and never fakes `accepted` — the
/// feedback sheet surfaces `common.notConnected` via the `failed`
/// presentation state and the draft is retained for retry.
///
/// Constructed in `AppDependencies.production` and `AppDependencies.inMemory`
/// as the default until an endpoint is configured. A test that wants the live
/// accept path injects `InMemoryFeedbackTransport` instead.
final class NoopFeedbackTransport implements FeedbackTransport {
  const NoopFeedbackTransport();

  @override
  Future<FeedbackResult> submit(FeedbackSubmission submission) async =>
      const FeedbackResult.unavailable();

  @override
  Future<FeedbackTriageState> status(String id) async => FeedbackTriageState.unavailable;
}
