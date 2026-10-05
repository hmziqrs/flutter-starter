import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/preferences/bool_codec.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// [AnalyticsClient] decorator enforcing the `analytics.opt_in` SecureStore key
/// (default off, per plans/feature_roadmap/features/analytics.md) on every
/// delegated emission — the production composite routes every real backend
/// through this gate. A store failure degrades to off, never to a throw.
final class OptInGatedAnalyticsClient implements AnalyticsClient {
  OptInGatedAnalyticsClient({required this.delegate, required this.secureStore});

  final AnalyticsClient delegate;
  final SecureStore secureStore;

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (await _optedIn()) await delegate.track(event);
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    if (await _optedIn()) await delegate.setUserProperty(property);
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (await _optedIn()) await delegate.setUserId(userId);
  }

  Future<bool> _optedIn() async {
    try {
      return await secureStore.readBool(analyticsOptInKey);
    } on Object {
      return false;
    }
  }
}
