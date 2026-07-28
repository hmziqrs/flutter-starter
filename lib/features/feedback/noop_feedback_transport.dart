import 'package:starter/features/feedback/feedback_transport.dart';

/// Noop [FeedbackTransport] for the no-backend production default.
///
/// Mirrors `InMemoryOtpRepository` / `NoopAnalyticsClient`. Honors the
/// no-backend rule (C2) and the honest-feedback guardrail (#13): `submit`
/// returns `FeedbackResult.unavailable` and **never fakes `accepted`** — the
/// feedback sheet surfaces `common.notConnected` via the `failed` presentation
/// state, the persisted draft is retained for retry, and the optional
/// screenshot toggle is inert.
///
/// This dual-purpose default is distinct from genuinely test-only fakes: it
/// is constructed in `AppDependencies.production` and `AppDependencies.inMemory`,
/// and is the production default until an endpoint is configured. A test that
/// wants to drive the live accept path injects `InMemoryFeedbackTransport` (or
/// the real HTTP adapter pointed at the test server) instead — never a Mocktail
/// of success in a production code path.
final class NoopFeedbackTransport implements FeedbackTransport {
  const NoopFeedbackTransport();

  @override
  Future<FeedbackResult> submit(FeedbackSubmission submission) async {
    // No backend: surface unavailable rather than fabricating an accepted id.
    // Returning `unavailable` keeps the controller on the honest `failed` path
    // and the draft stays persisted for a later retry once wiring lands.
    return const FeedbackResult.unavailable();
  }

  @override
  Future<FeedbackTriageState> status(String id) async {
    // No backend: no status is knowable. Surface unavailable honestly rather
    // than fabricating a queued / triaged state (C2 / guardrail #13).
    return FeedbackTriageState.unavailable;
  }
}
