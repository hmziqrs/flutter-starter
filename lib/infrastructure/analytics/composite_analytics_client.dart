import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// [AnalyticsClient] that fans every call out to a list of backends,
/// sequentially, each isolated in its own `try/on Object` so one failing or
/// unavailable backend never blocks the rest. Constructed at the composition
/// root to dual-report analytics (e.g. PostHog and Firebase Analytics).
final class CompositeAnalyticsClient implements AnalyticsClient {
  CompositeAnalyticsClient(List<AnalyticsClient> clients)
    : _clients = List<AnalyticsClient>.unmodifiable(clients);

  final List<AnalyticsClient> _clients;

  @override
  Future<void> track(AnalyticsEvent event) => _fanOut((c) => c.track(event));

  @override
  Future<void> setUserProperty(UserProperty property) =>
      _fanOut((c) => c.setUserProperty(property));

  @override
  Future<void> setUserId(String? userId) => _fanOut((c) => c.setUserId(userId));

  Future<void> _fanOut(Future<void> Function(AnalyticsClient client) call) async {
    for (final client in _clients) {
      try {
        await call(client);
      } on Object {
        // A single backend failure must never block the remaining backends.
      }
    }
  }
}
