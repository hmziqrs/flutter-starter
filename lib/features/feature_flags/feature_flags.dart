import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flags.freezed.dart';

/// The primitive a known flag decodes to from the remote-config `flags`
/// slice: a boolean gate, a string config value, or an integer rollout
/// percentage.
enum FeatureFlagKind { boolean, text, integer }

/// Known feature-flag keys exposed by the typed `FeatureFlags` value object.
///
/// Adding a flag: add a variant here with its `kind` and backend `wireKey`,
/// add a typed field on `FeatureFlags`, seed it in `FeatureFlags.defaults`,
/// and add a `case` to every exhaustive switch over `FeatureFlag`
/// (`fromSlice`, `isEnabled`, `_valueFor`, `copyWith`, `==`, `hashCode`) —
/// analysis fails if any switch is missing a case. The public API never
/// exposes a raw `Map<String, Object>` of flags.
enum FeatureFlag {
  /// Staged rollout of the redesigned onboarding flow.
  onboardingRevamp(kind: FeatureFlagKind.boolean, wireKey: 'onboarding_revamp'),

  /// Staged rollout of the redesigned home screen.
  homeRedesign(kind: FeatureFlagKind.boolean, wireKey: 'home_redesign'),

  /// Dark launch of the v2 checkout (traffic-shaped, not yet user-visible).
  checkoutV2(kind: FeatureFlagKind.boolean, wireKey: 'checkout_v2'),

  /// Kill switch for background profile sync.
  profileSync(kind: FeatureFlagKind.boolean, wireKey: 'profile_sync'),

  /// String config: which search backend to query (`'local'` = no backend).
  searchBackend(kind: FeatureFlagKind.text, wireKey: 'search_backend'),

  /// Integer config: checkout-v2 rollout percentage in the range 0–100.
  checkoutRolloutPercent(
    kind: FeatureFlagKind.integer,
    wireKey: 'checkout_rollout_percent',
  );

  const FeatureFlag({required this.kind, required this.wireKey});

  /// The decoded primitive this flag carries.
  final FeatureFlagKind kind;

  /// Backend wire key in the `flags` slice of the remote-config payload.
  final String wireKey;
}

/// Immutable, typed view of every known feature flag: typed fields, a
/// `FeatureFlags.defaults` no-backend baseline (every boolean gate disabled,
/// search backend at the local fallback, rollout percentage zero),
/// `copyWith`, and value equality.
///
/// No `Map<String, Object>` accessor — every flag is a typed field; dynamic
/// lookup goes through `isEnabled`, whose exhaustive switch keeps the typed
/// and dynamic views in lockstep.
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

  /// No-backend baseline: every boolean gate disabled, search backend at the
  /// local fallback, rollout percentage zero.
  const FeatureFlags.defaults()
    : onboardingRevamp = false,
      homeRedesign = false,
      checkoutV2 = false,
      profileSync = false,
      searchBackend = _defaultSearchBackend,
      checkoutRolloutPercent = 0;

  /// Decodes the `flags` slice of a remote-config payload. Unknown wire keys
  /// are ignored; missing or malformed values keep the `defaults` entry for
  /// that flag rather than fabricating an enabled flag.
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

  /// Search backend value meaning "no remote backend configured".
  static const _defaultSearchBackend = 'local';

  /// Lower/upper bound for `checkoutRolloutPercent`; out-of-range backend
  /// values are clamped to this range on decode.
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

  /// Dynamic, typed lookup of whether `flag` is "active". For boolean flags
  /// this is the literal value; for string/integer config flags it is `true`
  /// when the value differs from the no-backend baseline.
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

  /// Typed wire representation for the diagnostics read-out and an optional
  /// cache write-through.
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
