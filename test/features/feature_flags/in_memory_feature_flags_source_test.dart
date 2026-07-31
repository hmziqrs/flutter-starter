import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';

void main() {
  group('InMemoryFeatureFlagsSource', () {
    test('default load returns the no-backend baseline and never fakes enabled', () async {
      final source = InMemoryFeatureFlagsSource();
      addTearDown(source.dispose);
      expect(await source.load(), const FeatureFlags.defaults());
      expect(source.current, const FeatureFlags.defaults());
    });

    test('seeded initial value is returned by load', () async {
      final seeded = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      final source = InMemoryFeatureFlagsSource(initial: seeded);
      addTearDown(source.dispose);
      expect(await source.load(), seeded);
    });

    test('emit pushes the new value onto the changes stream', () async {
      final source = InMemoryFeatureFlagsSource();
      addTearDown(source.dispose);
      final first = source.changes().first;

      final next = FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': true,
        'checkout_rollout_percent': 50,
      });
      source.emit(next);

      expect(await first, next);
      expect(source.current, next);
      expect(await source.load(), next);
    });

    test('emit delivers multiple values in order to a broadcast subscriber', () async {
      final source = InMemoryFeatureFlagsSource();
      addTearDown(source.dispose);
      final received = <FeatureFlags>[];
      final subscription = source.changes().listen(received.add);
      addTearDown(subscription.cancel);

      final a = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      final b = FeatureFlags.fromSlice(const <String, Object?>{'profile_sync': true});
      source
        ..emit(a)
        ..emit(b);

      expect(received, [a, b]);
    });

    test('load does not emit on the changes stream (no double-emit)', () async {
      final source = InMemoryFeatureFlagsSource();
      addTearDown(source.dispose);
      final received = <FeatureFlags>[];
      final subscription = source.changes().listen(received.add);
      addTearDown(subscription.cancel);

      await source.load();
      await source.load();

      expect(received, isEmpty);
    });

    test('dispose closes the changes stream', () async {
      final source = InMemoryFeatureFlagsSource();
      final done = source.changes().isEmpty;
      source.dispose();
      expect(await done, isTrue);
    });
  });
}
