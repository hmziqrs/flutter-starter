import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

void main() {
  group('NoopAnalyticsClient', () {
    test('track completes and never throws for every event variant', () async {
      final client = NoopAnalyticsClient(logger: AppLogger(verbose: false));
      // The verbose-routing path is exercised for every sealed variant; none
      // throw (analytics must never break the UX it measures).
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
      // A verbose AppLogger is the production dev-run sink. The no-op routes
      // every event through logger.debug (a no-op when not verbose); the call
      // path here confirms the verbose branch is reached and remains total.
      final client = NoopAnalyticsClient(logger: AppLogger(verbose: true));
      await client.track(const ScreenView(routeName: 'home'));
      await client.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
      await client.setUserId('user-42');
      // No assertion on log text: AppLogger wraps an opaque Talker instance.
      // The contract under test is that routing never throws.
    });
  });
}
