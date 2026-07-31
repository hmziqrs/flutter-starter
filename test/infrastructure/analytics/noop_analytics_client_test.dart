import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

void main() {
  group('NoopAnalyticsClient', () {
    test('track completes and never throws for every event variant', () async {
      final client = NoopAnalyticsClient(logger: AppLogger(verbose: false));
      await expectLater(
        client.track(const ScreenView(routeName: 'home')),
        completes,
      );
      await expectLater(client.track(const Tap(target: 'cta')), completes);
      await expectLater(
        client.track(const FunnelStep(name: 'signup', step: 0)),
        completes,
      );
    });

    test('setUserProperty and setUserId complete and never throw', () async {
      final client = NoopAnalyticsClient(logger: AppLogger(verbose: false));
      await expectLater(
        client.setUserProperty(const UserProperty(key: 'plan', value: 'pro')),
        completes,
      );
      await expectLater(client.setUserId('user-42'), completes);
      await expectLater(client.setUserId(null), completes);
    });

    test('routes through AppLogger when verbose without throwing', () async {
      final client = NoopAnalyticsClient(logger: AppLogger(verbose: true));
      await client.track(const ScreenView(routeName: 'home'));
      await client.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
      await client.setUserId('user-42');
    });
  });
}
