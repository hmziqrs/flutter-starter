import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';

part 'settings_state.freezed.dart';

enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

enum AppSpacingVariant {
  compact(0.85),
  standard(1),
  relaxed(1.2);

  const AppSpacingVariant(this.scaleFactor);

  final double scaleFactor;
}

enum AppRadiusVariant {
  sharp(0),
  rounded(1),
  extraRound(1.5);

  const AppRadiusVariant(this.scaleFactor);

  final double scaleFactor;
}

@Freezed(copyWith: false)
class SettingsState with _$SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.accent,
    required this.fontScale,
    required this.textPreset,
    required this.spacingVariant,
    required this.radiusVariant,
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
      spacingVariant = AppSpacingVariant.standard,
      radiusVariant = AppRadiusVariant.rounded,
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
  @override
  final AppSpacingVariant spacingVariant;
  @override
  final AppRadiusVariant radiusVariant;

  String? get fontFamily => textPreset.toSettings().fontFamily;

  @override
  final AppLocale? localeOverride;

  @override
  final bool hasCompletedOnboarding;

  @override
  final bool biometricUnlockEnabled;

  @override
  final bool hapticsEnabled;

  @override
  final bool passcodeEnabled;

  @override
  final int autoLockDelaySeconds;

  @override
  final bool lockOnBackground;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppAccent? accent,
    double? fontScale,
    AppTextPreset? textPreset,
    AppSpacingVariant? spacingVariant,
    AppRadiusVariant? radiusVariant,
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
      spacingVariant: spacingVariant ?? this.spacingVariant,
      radiusVariant: radiusVariant ?? this.radiusVariant,
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
