import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw StateError('SettingsRepository must be overridden at the composition root.'),
);

final initialSettingsProvider = Provider<SettingsState>(
  (ref) => const SettingsState.defaults(),
);

final settingsControllerProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

final class SettingsController extends Notifier<SettingsState> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  SettingsState build() => ref.watch(initialSettingsProvider);

  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _replace(state.copyWith(themeMode: themeMode));
  }

  Future<void> setAccent(AppAccent accent) {
    return _replace(state.copyWith(accent: accent));
  }

  Future<void> setFontScale(double fontScale) {
    final normalized = fontScale.clamp(
      SettingsState.minimumFontScale,
      SettingsState.maximumFontScale,
    );
    return _replace(state.copyWith(fontScale: normalized));
  }

  /// Resolves [preset] to its clamped `(fontScale, fontFamily)` tuple; the
  /// manual [setFontScale] slider is untouched so a user can fine-tune after.
  Future<void> setTextPreset(AppTextPreset preset) {
    final resolved = preset.toSettings();
    return _replace(state.copyWith(textPreset: preset, fontScale: resolved.fontScale));
  }

  Future<void> setHapticsEnabled({required bool enabled}) {
    return _replace(state.copyWith(hapticsEnabled: enabled));
  }

  /// The synchronous write inside [_replace] happens before the first await,
  /// so a same-tick navigation to home never observes a stale onboarding flag.
  Future<void> markOnboardingComplete() {
    return _replace(state.copyWith(hasCompletedOnboarding: true));
  }

  Future<void> setBiometricUnlockEnabled({required bool enabled}) {
    return _replace(state.copyWith(biometricUnlockEnabled: enabled));
  }

  /// Enabling pushes the passcode-setup route; the gate doesn't arm until a
  /// passcode is actually configured there.
  Future<void> setPasscodeEnabled({required bool enabled}) {
    return _replace(state.copyWith(passcodeEnabled: enabled));
  }

  /// Idle auto-lock delay in seconds (0 = off); only meaningful with a
  /// passcode configured.
  Future<void> setAutoLockDelaySeconds(int seconds) {
    return _replace(state.copyWith(autoLockDelaySeconds: seconds < 0 ? 0 : seconds));
  }

  Future<void> setLockOnBackground({required bool enabled}) {
    return _replace(state.copyWith(lockOnBackground: enabled));
  }

  Future<void> setLocale(AppLocale? locale) async {
    final previous = state;
    final next = locale == null
        ? state.copyWith(followSystemLocale: true)
        : state.copyWith(localeOverride: locale);

    state = next;
    try {
      if (locale == null) {
        await LocaleSettings.useDeviceLocale();
      } else {
        await LocaleSettings.setLocale(locale);
      }
      await _repository.save(next);
    } on Object {
      state = previous;
      if (previous.localeOverride case final previousLocale?) {
        await LocaleSettings.setLocale(previousLocale);
      } else {
        await LocaleSettings.useDeviceLocale();
      }
      rethrow;
    }
  }

  Future<void> _replace(SettingsState next) async {
    final previous = state;
    state = next;
    try {
      await _repository.save(next);
    } on Object {
      state = previous;
      rethrow;
    }
  }
}
