import 'package:flutter/foundation.dart';
import 'package:starter/i18n/translations.g.dart';

enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

@immutable
final class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.accent,
    required this.fontScale,
    required this.localeOverride,
    this.hasCompletedOnboarding = false,
    this.biometricUnlockEnabled = false,
  });

  const SettingsState.defaults()
    : themeMode = AppThemeMode.system,
      accent = AppAccent.neutral,
      fontScale = 1,
      localeOverride = null,
      hasCompletedOnboarding = false,
      biometricUnlockEnabled = false;

  static const minimumFontScale = 0.85;
  static const maximumFontScale = 1.6;
  static const fontScaleStep = 0.05;

  final AppThemeMode themeMode;
  final AppAccent accent;
  final double fontScale;
  final AppLocale? localeOverride;

  /// Whether the first-launch onboarding flow has been completed. Seeded
  /// synchronously from persisted settings at cold start and toggled by the
  /// settings controller's mark-onboarding-complete action. The onboarding
  /// redirect reads the live controller state (not a captured bool) so the
  /// in-session Skip transition reaches home on the same tick.
  final bool hasCompletedOnboarding;

  /// Whether the user has opted into biometric unlock. Read by the C5 redirect
  /// (composition root) alongside the biometric lock state to gate protected
  /// shell-tab destinations to the lock page. Default false; persisted through
  /// the settings repository like every other plaintext preference.
  final bool biometricUnlockEnabled;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppAccent? accent,
    double? fontScale,
    AppLocale? localeOverride,
    bool? hasCompletedOnboarding,
    bool? biometricUnlockEnabled,
    bool followSystemLocale = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      fontScale: fontScale ?? this.fontScale,
      localeOverride: followSystemLocale ? null : (localeOverride ?? this.localeOverride),
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      biometricUnlockEnabled: biometricUnlockEnabled ?? this.biometricUnlockEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsState &&
            themeMode == other.themeMode &&
            accent == other.accent &&
            fontScale == other.fontScale &&
            localeOverride == other.localeOverride &&
            hasCompletedOnboarding == other.hasCompletedOnboarding &&
            biometricUnlockEnabled == other.biometricUnlockEnabled;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    accent,
    fontScale,
    localeOverride,
    hasCompletedOnboarding,
    biometricUnlockEnabled,
  );
}
