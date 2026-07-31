import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

enum FeatureFlagKind { boolean, text, integer }

enum FeatureFlag {
  onboardingRevamp(kind: FeatureFlagKind.boolean, wireKey: 'onboarding_revamp'),

  homeRedesign(kind: FeatureFlagKind.boolean, wireKey: 'home_redesign'),

  checkoutV2(kind: FeatureFlagKind.boolean, wireKey: 'checkout_v2'),

  profileSync(kind: FeatureFlagKind.boolean, wireKey: 'profile_sync'),

  searchBackend(kind: FeatureFlagKind.text, wireKey: 'search_backend'),

  checkoutRolloutPercent(
    kind: FeatureFlagKind.integer,
    wireKey: 'checkout_rollout_percent',
  );

  const FeatureFlag({required this.kind, required this.wireKey});

  final FeatureFlagKind kind;

  final String wireKey;
}

@freezed
class FeatureFlags with _$FeatureFlags {
  const FeatureFlags({
    required this.onboardingRevamp,
    required this.homeRedesign,
    required this.checkoutV2,
    required this.profileSync,
    required this.searchBackend,
    required this.checkoutRolloutPercent,
  });

  const FeatureFlags.defaults()
    : onboardingRevamp = false,
      homeRedesign = false,
      checkoutV2 = false,
      profileSync = false,
      searchBackend = _defaultSearchBackend,
      checkoutRolloutPercent = 0;

  factory FeatureFlags.fromSlice(Map<String, Object?>? slice) {
    var onboardingRevamp = false;
    var homeRedesign = false;
    var checkoutV2 = false;
    var profileSync = false;
    var searchBackend = _defaultSearchBackend;
    var checkoutRolloutPercent = 0;

    if (slice != null) {
      for (final flag in FeatureFlag.values) {
        final raw = slice[flag.wireKey];
        switch (flag) {
          case FeatureFlag.onboardingRevamp:
            if (raw is bool) {
              onboardingRevamp = raw;
            }
          case FeatureFlag.homeRedesign:
            if (raw is bool) {
              homeRedesign = raw;
            }
          case FeatureFlag.checkoutV2:
            if (raw is bool) {
              checkoutV2 = raw;
            }
          case FeatureFlag.profileSync:
            if (raw is bool) {
              profileSync = raw;
            }
          case FeatureFlag.searchBackend:
            if (raw is String) {
              searchBackend = raw;
            }
          case FeatureFlag.checkoutRolloutPercent:
            final percent = _coercePercent(raw);
            if (percent != null) {
              checkoutRolloutPercent = percent;
            }
        }
      }
    }

    return FeatureFlags(
      onboardingRevamp: onboardingRevamp,
      homeRedesign: homeRedesign,
      checkoutV2: checkoutV2,
      profileSync: profileSync,
      searchBackend: searchBackend,
      checkoutRolloutPercent: checkoutRolloutPercent,
    );
  }

  static const _defaultSearchBackend = 'local';

  static const minimumRolloutPercent = 0;
  static const maximumRolloutPercent = 100;

  @override
  final bool onboardingRevamp;
  @override
  final bool homeRedesign;
  @override
  final bool checkoutV2;
  @override
  final bool profileSync;
  @override
  final String searchBackend;
  @override
  final int checkoutRolloutPercent;

  bool isEnabled(FeatureFlag flag) {
    return switch (flag) {
      FeatureFlag.onboardingRevamp => onboardingRevamp,
      FeatureFlag.homeRedesign => homeRedesign,
      FeatureFlag.checkoutV2 => checkoutV2,
      FeatureFlag.profileSync => profileSync,
      FeatureFlag.searchBackend => searchBackend != _defaultSearchBackend,
      FeatureFlag.checkoutRolloutPercent => checkoutRolloutPercent > 0,
    };
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      for (final flag in FeatureFlag.values) flag.wireKey: _valueFor(flag),
    };
  }

  Object? _valueFor(FeatureFlag flag) {
    return switch (flag) {
      FeatureFlag.onboardingRevamp => onboardingRevamp,
      FeatureFlag.homeRedesign => homeRedesign,
      FeatureFlag.checkoutV2 => checkoutV2,
      FeatureFlag.profileSync => profileSync,
      FeatureFlag.searchBackend => searchBackend,
      FeatureFlag.checkoutRolloutPercent => checkoutRolloutPercent,
    };
  }

  static int? _coercePercent(Object? raw) {
    final num numeric;
    if (raw is int) {
      numeric = raw;
    } else if (raw is double) {
      numeric = raw;
    } else {
      return null;
    }
    return numeric.toInt().clamp(minimumRolloutPercent, maximumRolloutPercent);
  }
}
