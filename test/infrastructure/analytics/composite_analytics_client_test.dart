import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/composite_analytics_client.dart';
import 'package:starter/infrastructure/analytics/recording_analytics_client.dart';

class _ThrowingAnalyticsClient implements AnalyticsClient {
  @override
  Future<void> track(AnalyticsEvent event) async {
    throw StateError('analytics boom');
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    throw StateError('analytics boom');
  }

  @override
  Future<void> setUserId(String? userId) async {
    throw StateError('analytics boom');
  }
}

void main() {
  group('CompositeAnalyticsClient', () {
    test('is an AnalyticsClient', () {
      expect(CompositeAnalyticsClient(const []), isA<AnalyticsClient>());
    });

    test('fans track out to every backend in order', () async {
      final first = RecordingAnalyticsClient();
      final second = RecordingAnalyticsClient();
      final composite = CompositeAnalyticsClient([first, second]);

      await composite.track(const ScreenView(routeName: 'home'));
      await composite.track(const Tap(target: 'cta'));
      await composite.track(const FunnelStep(name: 'signup', step: 0));

      expect(first.events, equals(second.events));
      expect(first.events, hasLength(3));
    });

    test('fans identity + property calls out to every backend', () async {
      final first = RecordingAnalyticsClient();
      final second = RecordingAnalyticsClient();
      final composite = CompositeAnalyticsClient([first, second]);

      await composite.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
      await composite.setUserId('user-42');
      await composite.setUserId(null);

      expect(first.properties, equals(second.properties));
      expect(first.properties.single.key, 'plan');
      expect(first.userId, isNull);
      expect(second.userId, isNull);
    });

    test('a throwing backend never blocks the remaining backends', () async {
      final healthy = RecordingAnalyticsClient();
      final composite = CompositeAnalyticsClient([
        _ThrowingAnalyticsClient(),
        healthy,
        _ThrowingAnalyticsClient(),
      ]);

      await expectLater(
        composite.track(const Tap(target: 'cta')),
        completes,
      );
      await expectLater(
        composite.setUserProperty(const UserProperty(key: 'plan', value: 'pro')),
        completes,
      );
      await expectLater(composite.setUserId('user-42'), completes);

      expect(healthy.events.single, const Tap(target: 'cta'));
      expect(healthy.properties.single.key, 'plan');
      expect(healthy.userId, 'user-42');
    });

    test('an empty delegate list never throws', () async {
      final composite = CompositeAnalyticsClient(const []);
      await expectLater(composite.track(const Tap(target: 'cta')), completes);
      await expectLater(composite.setUserId(null), completes);
    });
  });
}
