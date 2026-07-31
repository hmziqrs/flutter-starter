import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';

/// Skips `analyticsOptInKey`; GA4 collection is toggled via the Firebase console.
final class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient();

  FirebaseAnalytics? _analytics;
  bool _resolveFailed = false;

  Future<FirebaseAnalytics?> _resolve() async {
    if (_analytics != null) {
      return _analytics;
    }
    if (_resolveFailed) {
      return null;
    }
    try {
      return _analytics = FirebaseAnalytics.instance;
    } on Object {
      _resolveFailed = true;
      return null;
    }
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      switch (event) {
        case ScreenView(:final routeName):
          await analytics.logScreenView(screenName: routeName);
        case Tap(:final target):
          await analytics.logEvent(
            name: 'tap',
            parameters: <String, Object>{'target': target},
          );
        case FunnelStep(:final name, :final step):
          await analytics.logEvent(
            name: 'funnel_step',
            parameters: <String, Object>{'name': name, 'step': step},
          );
      }
    } on Object {
      // Swallow: analytics must never break the UX it measures.
    }
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      await analytics.setUserProperty(name: property.key, value: property.value);
    } on Object {
      // Swallow; see [track].
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      await analytics.setUserId(id: userId);
    } on Object {
      // Swallow; see [track].
    }
  }
}
