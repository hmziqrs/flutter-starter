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

  /// The optional Latin-only font family derived from the active [textPreset]
  /// (null for comfortable/large; the dyslexia family for the dyslexia preset).
  /// Kept as a computed getter rather than a denormalized field so it can never
  /// drift from [textPreset] — switching dyslexia -> comfortable clears it
  /// without a copyWith clearability workaround. Persisted indirectly via
  /// [textPreset] (no separate key); non-Latin locales keep their bundled
  /// `Noto Sans Arabic` / `Noto Sans SC` fallback through `fontFamilyFallback`.
  String? get fontFamily => textPreset.toSettings().fontFamily;

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

  /// Whether haptic feedback is enabled on key actions. Default true; only the
  /// opt-out is persisted so a missing key reads as enabled. Each call site
  /// additionally gates on `MediaQuery.disableAnimationsOf` (the reduce-motion
  /// guard is load-bearing and applied per-consumer, never centrally).
  final bool hapticsEnabled;

  /// Whether a passcode is configured and the passcode gate is armed. Read by
  /// the C5 redirect (composition root) alongside PasscodeState to gate
  /// protected shell-tab destinations to the passcode entry page. Default
  /// false; persisted as a plaintext preference (the secret itself never
  /// leaves SecureStore — only the salted hash does).
  final bool passcodeEnabled;

  /// Idle auto-lock delay in seconds. 0 means idle locking is off (the lock
  /// only fires on background-return when [lockOnBackground] is true).
  /// Persisted as a plaintext preference; the live value is read by the
  /// AutoLockController through the `autoLockDelaySecondsProvider` seam.
  final int autoLockDelaySeconds;

  /// Whether the app re-locks when backgrounded. Only meaningful when
  /// [passcodeEnabled] is true. Persisted as a plaintext preference.
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
