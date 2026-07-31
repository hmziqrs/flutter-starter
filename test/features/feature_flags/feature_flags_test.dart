import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';

void main() {
  group('FeatureFlags.defaults', () {
    test('disables every boolean gate (honest no-backend baseline)', () {
      const flags = FeatureFlags.defaults();
      expect(flags.onboardingRevamp, isFalse);
      expect(flags.homeRedesign, isFalse);
      expect(flags.checkoutV2, isFalse);
      expect(flags.profileSync, isFalse);
      expect(flags.searchBackend, 'local');
      expect(flags.checkoutRolloutPercent, 0);
    });

    test('isEnabled reports nothing active for the baseline', () {
      const flags = FeatureFlags.defaults();
      for (final flag in FeatureFlag.values) {
        expect(flags.isEnabled(flag), isFalse, reason: flag.name);
      }
    });
  });

  group('FeatureFlags.fromSlice', () {
    test('null slice yields the defaults baseline', () {
      expect(FeatureFlags.fromSlice(null), const FeatureFlags.defaults());
    });

    test('empty slice yields the defaults baseline', () {
      expect(
        FeatureFlags.fromSlice(const <String, Object?>{}),
        const FeatureFlags.defaults(),
      );
    });

    test('decodes typed booleans, string, and integer values', () {
      final flags = FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': true,
        'home_redesign': false,
        'checkout_v2': true,
        'profile_sync': true,
        'search_backend': 'algolia',
        'checkout_rollout_percent': 42,
      });
      expect(flags.onboardingRevamp, isTrue);
      expect(flags.homeRedesign, isFalse);
      expect(flags.checkoutV2, isTrue);
      expect(flags.profileSync, isTrue);
      expect(flags.searchBackend, 'algolia');
      expect(flags.checkoutRolloutPercent, 42);
    });

    test('isEnabled flips for an overridden string/integer config', () {
      final flags = FeatureFlags.fromSlice(const <String, Object?>{
        'checkout_v2': true,
        'search_backend': 'algolia',
        'checkout_rollout_percent': 1,
      });
      expect(flags.isEnabled(FeatureFlag.checkoutV2), isTrue);
      expect(flags.isEnabled(FeatureFlag.searchBackend), isTrue);
      expect(flags.isEnabled(FeatureFlag.checkoutRolloutPercent), isTrue);
      expect(flags.isEnabled(FeatureFlag.onboardingRevamp), isFalse);
    });

    test('malformed values fall back to the baseline (never fabricate enabled)', () {
      final flags = FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': 'yes',
        'checkout_v2': 1,
        'search_backend': 7,
        'checkout_rollout_percent': 'half',
      });
      expect(flags, const FeatureFlags.defaults());
    });

    test('clamps rollout percent into the 0–100 range', () {
      expect(
        FeatureFlags.fromSlice(const <String, Object?>{
          'checkout_rollout_percent': 250,
        }).checkoutRolloutPercent,
        100,
      );
      expect(
        FeatureFlags.fromSlice(const <String, Object?>{
          'checkout_rollout_percent': -5,
        }).checkoutRolloutPercent,
        0,
      );
    });

    test('accepts a double rollout percent and truncates to int', () {
      expect(
        FeatureFlags.fromSlice(const <String, Object?>{
          'checkout_rollout_percent': 12.9,
        }).checkoutRolloutPercent,
        12,
      );
    });

    test('ignores unknown wire keys', () {
      final flags = FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': true,
        'unknown_future_flag': true,
      });
      expect(flags.onboardingRevamp, isTrue);
      expect(flags.homeRedesign, isFalse);
    });
  });

  group('FeatureFlags value semantics', () {
    test('copyWith replaces only the provided fields', () {
      const base = FeatureFlags.defaults();
      final next = base.copyWith(checkoutV2: true, searchBackend: 'algolia');
      expect(next.checkoutV2, isTrue);
      expect(next.searchBackend, 'algolia');
      expect(next.onboardingRevamp, base.onboardingRevamp);
      expect(next.checkoutRolloutPercent, base.checkoutRolloutPercent);
    });

    test('== / hashCode treat equal field sets as equal', () {
      final a = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      final b = FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('toMap round-trips wire keys for every known flag', () {
      final flags = FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': true,
        'checkout_rollout_percent': 33,
      });
      final map = flags.toMap();
      expect(map.length, FeatureFlag.values.length);
      expect(map['onboarding_revamp'], true);
      expect(map['checkout_rollout_percent'], 33);
      expect(map['search_backend'], 'local');
    });
  });

  test('FeatureFlag.wireKey is unique across known flags', () {
    final keys = FeatureFlag.values.map((f) => f.wireKey).toSet();
    expect(keys.length, FeatureFlag.values.length);
  });
}
