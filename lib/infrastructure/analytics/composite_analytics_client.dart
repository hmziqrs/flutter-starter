import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// [AnalyticsClient] that fans every call out to a list of backends in
/// parallel.
///
/// Constructed at the composition root to dual-report analytics — e.g. PostHog
/// (or the no-backend default) **and** Firebase Analytics — so each backend
/// receives the same events without the other's failures blocking it. Each
/// delegate is invoked inside its own `try/on Object` so a throwing backend
/// (or a backend whose SDK is unavailable on the current host) never prevents
/// the remaining delegates from receiving the event. The contract that
/// [AnalyticsClient] methods never throw is therefore preserved: this composite
/// itself never throws for backend failures.
///
/// Delegates are invoked in insertion order and awaited sequentially. Analytics
/// is fire-and-forget on the main isolate, so the small serialization cost is
/// irrelevant; the sequential await guarantees one slow backend does not starve
/// a faster one of ordering guarantees within a single emit.
final class CompositeAnalyticsClient implements AnalyticsClient {
  CompositeAnalyticsClient(List<AnalyticsClient> clients)
    : _clients = List<AnalyticsClient>.unmodifiable(clients);

  final List<AnalyticsClient> _clients;

  @override
  Future<void> track(AnalyticsEvent event) async {
    for (final client in _clients) {
      try {
        await client.track(event);
      } on Object {
        // A single backend failure must never block the remaining backends.
      }
    }
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    for (final client in _clients) {
      try {
        await client.setUserProperty(property);
      } on Object {
        // A single backend failure must never block the remaining backends.
      }
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    for (final client in _clients) {
      try {
        await client.setUserId(userId);
      } on Object {
        // A single backend failure must never block the remaining backends.
      }
    }
  }
}
