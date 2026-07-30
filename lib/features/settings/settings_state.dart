import 'package:flutter/foundation.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';

enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

@immutable
final class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.accent,
    required this.fontScale,
    required this.textPreset,
    required this.localeOverride,
    this.hasCompletedOnboarding = false,
    this.biometricUnlockEnabled = false,
    this.hapticsEnabled = true,
    this.passcodeEnabled = false,
    this.autoLockDelaySeconds = 0,
    this.lockOnBackground = false,
  });

  const SettingsState.defaults()
    : themeMode = AppThemeMode.system,
      accent = AppAccent.neutral,
      fontScale = 1,
      textPreset = AppTextPreset.comfortable,
      localeOverride = null,
      hasCompletedOnboarding = false,
      biometricUnlockEnabled = false,
      hapticsEnabled = true,
      passcodeEnabled = false,
      autoLockDelaySeconds = 0,
      lockOnBackground = false;

  static const minimumFontScale = 0.85;
  static const maximumFontScale = 1.6;
  static const fontScaleStep = 0.05;

  final AppThemeMode themeMode;
  final AppAccent accent;
  final double fontScale;
  final AppTextPreset textPreset;

  /// Derived from [textPreset] so it never drifts (null unless dyslexia).
  String? get fontFamily => textPreset.toSettings().fontFamily;

  final AppLocale? localeOverride;

  final bool hasCompletedOnboarding;

  final bool biometricUnlockEnabled;

  /// Default true; only the opt-out is persisted. Reduce-motion is gated
  /// per-consumer via `MediaQuery.disableAnimationsOf`, not centrally.
  final bool hapticsEnabled;

  /// Whether a passcode is configured and armed; the secret itself lives only
  /// as a salted hash in SecureStore.
  final bool passcodeEnabled;

  /// Idle auto-lock delay in seconds; 0 = off.
  final int autoLockDelaySeconds;

  /// Whether the app re-locks when backgrounded; meaningful only with
  /// [passcodeEnabled].
  final bool lockOnBackground;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppAccent? accent,
    double? fontScale,
    AppTextPreset? textPreset,
    AppLocale? localeOverride,
    bool? hasCompletedOnboarding,
    bool? biometricUnlockEnabled,
    bool? hapticsEnabled,
    bool? passcodeEnabled,
    int? autoLockDelaySeconds,
    bool? lockOnBackground,
    bool followSystemLocale = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      fontScale: fontScale ?? this.fontScale,
      textPreset: textPreset ?? this.textPreset,
      localeOverride: followSystemLocale ? null : (localeOverride ?? this.localeOverride),
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      biometricUnlockEnabled: biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      passcodeEnabled: passcodeEnabled ?? this.passcodeEnabled,
      autoLockDelaySeconds: autoLockDelaySeconds ?? this.autoLockDelaySeconds,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsState &&
            themeMode == other.themeMode &&
            accent == other.accent &&
            fontScale == other.fontScale &&
            textPreset == other.textPreset &&
            localeOverride == other.localeOverride &&
            hasCompletedOnboarding == other.hasCompletedOnboarding &&
            biometricUnlockEnabled == other.biometricUnlockEnabled &&
            hapticsEnabled == other.hapticsEnabled &&
            passcodeEnabled == other.passcodeEnabled &&
            autoLockDelaySeconds == other.autoLockDelaySeconds &&
            lockOnBackground == other.lockOnBackground;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    accent,
    fontScale,
    textPreset,
    localeOverride,
    hasCompletedOnboarding,
    biometricUnlockEnabled,
    hapticsEnabled,
    passcodeEnabled,
    autoLockDelaySeconds,
    lockOnBackground,
  );
}
