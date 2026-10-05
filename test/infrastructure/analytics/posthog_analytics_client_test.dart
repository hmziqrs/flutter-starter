import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/posthog_analytics_client.dart';
import 'package:starter/infrastructure/preferences/bool_codec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const posthogChannel = MethodChannel('posthog_flutter');
  final channelCalls = <(String method, Map<Object?, Object?> arguments)>[];

  Map<Object?, Object?> decodeArguments(Object? raw) {
    return raw is Map ? Map<Object?, Object?>.from(raw) : const <Object?, Object?>{};
  }

  setUp(() {
    channelCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      posthogChannel,
      (call) async {
        channelCalls.add((call.method, decodeArguments(call.arguments)));
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      posthogChannel,
      null,
    );
  });

  group('PosthogAnalyticsClient', () {
    test('emits nothing on the posthog channel before the user opts in', () async {
      final client = PosthogAnalyticsClient(secureStore: InMemorySecureStore());

      await client.setUserId('user-42');
      await client.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
      await client.track(const ScreenView(routeName: 'home'));
      await client.track(const Tap(target: 'cta'));
      await client.track(const FunnelStep(name: 'signup', step: 1));
      await client.setUserId(null);

      expect(channelCalls, isEmpty);
    });

    test('after opt-in every emission reaches the posthog channel in call order', () async {
      final secureStore = InMemorySecureStore();
      await secureStore.writeBool(analyticsOptInKey, value: true);
      final client = PosthogAnalyticsClient(secureStore: secureStore);

      await client.setUserId('user-42');
      await client.setUserProperty(const UserProperty(key: 'plan', value: 'pro'));
      await client.track(const Tap(target: 'cta'));
      await client.track(const FunnelStep(name: 'signup', step: 2));
      await client.track(const ScreenView(routeName: 'home'));
      await client.setUserId(null);

      final labels = <String>[
        for (final (method, arguments) in channelCalls)
          if (method == 'capture') 'capture:${arguments['eventName']}' else method,
      ];
      expect(labels, <String>[
        'identify',
        'setPersonProperties',
        'capture:tap',
        'capture:funnel_step',
        'screen',
        'reset',
      ]);

      final identify = channelCalls[0].$2;
      expect(identify['userId'], 'user-42');
      final personProperties = channelCalls[1].$2;
      expect(personProperties['userPropertiesToSet'], <String, Object>{'plan': 'pro'});
      final tap = channelCalls[2].$2;
      expect(tap['properties'], <String, Object>{'target': 'cta'});
      final funnelStep = channelCalls[3].$2;
      expect(funnelStep['properties'], <String, Object>{'name': 'signup', 'step': 2});
      expect(channelCalls[4].$2['screenName'], 'home');
    });

    test('a throwing platform handler never rethrows through the client', () async {
      final secureStore = InMemorySecureStore();
      await secureStore.writeBool(analyticsOptInKey, value: true);
      final client = PosthogAnalyticsClient(secureStore: secureStore);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        posthogChannel,
        (call) async {
          throw StateError('posthog method channel unavailable');
        },
      );

      await expectLater(client.setUserId('user-42'), completes);
      await expectLater(client.setUserId(null), completes);
      await expectLater(
        client.setUserProperty(const UserProperty(key: 'plan', value: 'pro')),
        completes,
      );
      await expectLater(client.track(const ScreenView(routeName: 'home')), completes);
      await expectLater(client.track(const Tap(target: 'cta')), completes);
      await expectLater(client.track(const FunnelStep(name: 'signup', step: 3)), completes);
    });
  });
}
