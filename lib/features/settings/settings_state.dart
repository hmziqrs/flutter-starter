import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';

part 'settings_state.freezed.dart';

enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

@Freezed(copyWith: false)
class SettingsState with _$SettingsState {
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

  @override
  final AppThemeMode themeMode;
  @override
  final AppAccent accent;
  @override
  final double fontScale;
  @override
  final AppTextPreset textPreset;

  /// Derived from [textPreset] so it never drifts (null unless dyslexia).
  String? get fontFamily => textPreset.toSettings().fontFamily;

  @override
  final AppLocale? localeOverride;

  @override
  final bool hasCompletedOnboarding;

  @override
  final bool biometricUnlockEnabled;

  /// Default true; only the opt-out is persisted. Reduce-motion is gated
  /// per-consumer via `MediaQuery.disableAnimationsOf`, not centrally.
  @override
  final bool hapticsEnabled;

  /// Whether a passcode is configured and armed; the secret itself lives only
  /// as a salted hash in SecureStore.
  @override
  final bool passcodeEnabled;

  /// Idle auto-lock delay in seconds; 0 = off.
  @override
  final int autoLockDelaySeconds;

  /// Whether the app re-locks when backgrounded; meaningful only with
  /// [passcodeEnabled].
  @override
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
}
