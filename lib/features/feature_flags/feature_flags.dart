import 'package:flutter/foundation.dart';

/// The primitive a known flag decodes to from the remote-config `flags` slice.
///
/// The exhaustive switch in `FeatureFlags.fromSlice` dispatches on
/// `FeatureFlag` (not on this kind), but `FeatureFlag.kind` documents the
/// expected wire shape and keeps the typed decode branches honest: a boolean
/// gate, a string config value, or an integer rollout percentage.
enum FeatureFlagKind { boolean, text, integer }

/// Known feature-flag keys exposed by the typed `FeatureFlags` value object.
///
/// Adding a flag is a four-step, analysis-checked edit:
/// 1. add a variant here with its `kind` and backend `wireKey`;
/// 2. add a typed field (and getter) on `FeatureFlags`;
/// 3. seed it in `FeatureFlags.defaults`;
/// 4. add a `case` to **every** exhaustive switch over `FeatureFlag` —
///    `FeatureFlags.fromSlice`, `FeatureFlags.isEnabled`,
///    `FeatureFlags._valueFor`, `FeatureFlags.copyWith` (via the named
///    parameter), `FeatureFlags.==`, and `FeatureFlags.hashCode`.
///
/// `flutter analyze --fatal-infos` fails the build if any switch is missing a
/// case, so the surface cannot drift. This is the "no `dynamic` flag bag"
/// guardrail (audit item 7): the public API never exposes a
/// `Map<String, Object>` of flags.
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

/// Immutable, typed view of every known feature flag.
///
/// Mirrors the `SettingsState` shape: an `@immutable` value object with typed
/// fields, a `FeatureFlags.defaults` no-backend baseline, `copyWith`, and value
/// equality. The honest no-backend baseline has **every boolean gate disabled**,
/// the search backend set to the local fallback, and the rollout percentage at
/// zero — a missing backend must never claim a flag is enabled when the baseline
/// says disabled (C2: never fake success; flags have no user-facing success
/// state, so the honest baseline is simply "everything off").
///
/// There is intentionally **no** `Map<String, Object>` accessor on this surface.
/// Every flag is a typed field; dynamic lookup goes through `isEnabled`, whose
/// exhaustive switch keeps the typed and dynamic views in lockstep.
@immutable
final class FeatureFlags {
  const FeatureFlags({
    required this.onboardingRevamp,
    required this.homeRedesign,
    required this.checkoutV2,
    required this.profileSync,
    required this.searchBackend,
    required this.checkoutRolloutPercent,
  });

  /// No-backend baseline. Every boolean gate is disabled, the search backend is
  /// the local fallback, and the rollout percentage is zero.
  const FeatureFlags.defaults()
    : onboardingRevamp = false,
      homeRedesign = false,
      checkoutV2 = false,
      profileSync = false,
      searchBackend = _defaultSearchBackend,
      checkoutRolloutPercent = 0;

  /// Decodes the `flags` slice of a remote-config payload.
  ///
  /// Unknown wire keys are ignored. Missing or malformed values keep the
  /// `FeatureFlags.defaults` entry for that flag — a corrupt or partial backend
  /// response never fabricates an enabled flag (C2). The exhaustive switch over
  /// `FeatureFlag` makes `flutter analyze --fatal-infos` fail if a new variant
  /// is added without a decode branch.
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

  FeatureFlags copyWith({
    bool? onboardingRevamp,
    bool? homeRedesign,
    bool? checkoutV2,
    bool? profileSync,
    String? searchBackend,
    int? checkoutRolloutPercent,
  }) {
    return FeatureFlags(
      onboardingRevamp: onboardingRevamp ?? this.onboardingRevamp,
      homeRedesign: homeRedesign ?? this.homeRedesign,
      checkoutV2: checkoutV2 ?? this.checkoutV2,
      profileSync: profileSync ?? this.profileSync,
      searchBackend: searchBackend ?? this.searchBackend,
      checkoutRolloutPercent: checkoutRolloutPercent ?? this.checkoutRolloutPercent,
    );
  }

  /// Search backend value that means "no remote backend configured". Kept as a
  /// named constant so `isEnabled` and the decode path agree on the baseline.
  static const _defaultSearchBackend = 'local';

  /// Lower/upper bound for `checkoutRolloutPercent`; out-of-range backend
  /// values are clamped to this range on decode.
  static const minimumRolloutPercent = 0;
  static const maximumRolloutPercent = 100;

  final bool onboardingRevamp;
  final bool homeRedesign;
  final bool checkoutV2;
  final bool profileSync;
  final String searchBackend;
  final int checkoutRolloutPercent;

  /// Dynamic, typed lookup of whether `flag` is "active". For boolean flags
  /// this is the literal value; for the string/integer config flags it is
  /// `true` when the value differs from the no-backend baseline (i.e. the
  /// backend has overridden it). The exhaustive switch guarantees a new
  /// `FeatureFlag` variant cannot ship without a branch here.
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
  /// cache write-through. The exhaustive switch keeps this in lockstep with the
  /// field set.
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeatureFlags &&
            onboardingRevamp == other.onboardingRevamp &&
            homeRedesign == other.homeRedesign &&
            checkoutV2 == other.checkoutV2 &&
            profileSync == other.profileSync &&
            searchBackend == other.searchBackend &&
            checkoutRolloutPercent == other.checkoutRolloutPercent;
  }

  @override
  int get hashCode => Object.hash(
    onboardingRevamp,
    homeRedesign,
    checkoutV2,
    profileSync,
    searchBackend,
    checkoutRolloutPercent,
  );
}
