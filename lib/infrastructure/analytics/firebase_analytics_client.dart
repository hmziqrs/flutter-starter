import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/firebase/lazy_firebase_instance.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';

final class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient();

  final LazyFirebaseInstance<FirebaseAnalytics> _instance = LazyFirebaseInstance<FirebaseAnalytics>(
    () async => FirebaseAnalytics.instance,
  );

  @override
  Future<void> track(AnalyticsEvent event) async {
    await _instance.runIfSupported((analytics) async {
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
    }, supported: firebaseAnalyticsSupported);
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    await _instance.runIfSupported(
      (analytics) async => analytics.setUserProperty(name: property.key, value: property.value),
      supported: firebaseAnalyticsSupported,
    );
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _instance.runIfSupported(
      (analytics) async => analytics.setUserId(id: userId),
      supported: firebaseAnalyticsSupported,
    );
  }
}
