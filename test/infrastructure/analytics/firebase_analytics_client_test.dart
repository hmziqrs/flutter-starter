import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/firebase_analytics_client.dart';

void main() {
  group('FirebaseAnalyticsClient', () {
    // Firebase is intentionally NOT initialized in this suite (no
    // Firebase.initializeApp), so resolving FirebaseAnalytics.instance throws
    // [core/no-app]. The adapter's guarded _resolve swallows that and the emit
    // becomes a no-op; the contract under test is that every method stays total
    // — analytics must never break the UX it measures — on every platform.

    test('is an AnalyticsClient', () {
      expect(FirebaseAnalyticsClient(), isA<AnalyticsClient>());
    });

    test('track never throws on a supported platform (Firebase uninitialized)', () async {
      final client = FirebaseAnalyticsClient();
      await expectLater(client.track(const ScreenView(routeName: 'home')), completes);
      await expectLater(client.track(const Tap(target: 'cta')), completes);
      await expectLater(client.track(const FunnelStep(name: 'signup', step: 0)), completes);
    });

    test('identity methods never throw on a supported platform', () async {
      final client = FirebaseAnalyticsClient();
      await expectLater(
        client.setUserProperty(const UserProperty(key: 'plan', value: 'pro')),
        completes,
      );
      await expectLater(client.setUserId('user-42'), completes);
      await expectLater(client.setUserId(null), completes);
    });

    test('a property name outside GA4 rules never throws', () async {
      // GA4 requires 1–24 alphanumeric keys with a leading alpha; the adapter
      // swallows the ArgumentError so a product key that violates the rule
      // never breaks the emit path.
      final client = FirebaseAnalyticsClient();
      await expectLater(
        client.setUserProperty(const UserProperty(key: '_invalid key!', value: 'x')),
        completes,
      );
    });

    group('on an unsupported platform (Linux)', () {
      TargetPlatform? previous;

      setUp(() => previous = debugDefaultTargetPlatformOverride);
      tearDown(() => debugDefaultTargetPlatformOverride = previous);

      test('every method early-returns and never throws', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final client = FirebaseAnalyticsClient();

        await expectLater(client.track(const ScreenView(routeName: 'home')), completes);
        await expectLater(client.track(const Tap(target: 'cta')), completes);
        await expectLater(
          client.setUserProperty(const UserProperty(key: 'plan', value: 'pro')),
          completes,
        );
        await expectLater(client.setUserId('user-42'), completes);
      });
    });
  });
}
