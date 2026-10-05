import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/opt_in_gated_analytics_client.dart';
import 'package:starter/infrastructure/analytics/recording_analytics_client.dart';

void main() {
  test('no emission before opt-in (SecureStore default off)', () async {
    final delegate = RecordingAnalyticsClient();
    final gated = OptInGatedAnalyticsClient(
      delegate: delegate,
      secureStore: InMemorySecureStore(),
    );

    await gated.track(const ScreenView(routeName: 'home'));
    await gated.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
    await gated.setUserId('user-42');

    expect(delegate.events, isEmpty);
    expect(delegate.properties, isEmpty);
    expect(delegate.userId, isNull);
  });

  test('emissions flow to the delegate once opted in', () async {
    final store = InMemorySecureStore();
    await store.write(analyticsOptInKey, 'true');
    final delegate = RecordingAnalyticsClient();
    final gated = OptInGatedAnalyticsClient(delegate: delegate, secureStore: store);

    await gated.track(const ScreenView(routeName: 'home'));
    await gated.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
    await gated.setUserId('user-42');

    expect(delegate.events.single, const ScreenView(routeName: 'home'));
    expect(delegate.properties.single.key, 'plan');
    expect(delegate.userId, 'user-42');
  });

  test('a failing store read degrades to off and never throws', () async {
    final delegate = RecordingAnalyticsClient();
    final gated = OptInGatedAnalyticsClient(
      delegate: delegate,
      secureStore: InMemorySecureStore()..failReads = true,
    );

    await expectLater(gated.track(const Tap(target: 'cta')), completes);
    expect(delegate.events, isEmpty);
  });
}
