import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/optimistic_notifier.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw StateError('SettingsRepository must be overridden at the composition root.'),
);

final initialSettingsProvider = Provider<SettingsState>(
  (ref) => const SettingsState.defaults(),
);

final settingsControllerProvider = NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

final class SettingsController extends Notifier<SettingsState>
    with OptimisticNotifier<SettingsState> {
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

  Future<void> setTextPreset(AppTextPreset preset) {
    final resolved = preset.toSettings();
    return _replace(state.copyWith(textPreset: preset, fontScale: resolved.fontScale));
  }

  Future<void> setHapticsEnabled({required bool enabled}) {
    return _replace(state.copyWith(hapticsEnabled: enabled));
  }

  Future<void> markOnboardingComplete() {
    return _replace(state.copyWith(hasCompletedOnboarding: true));
  }

  Future<void> setBiometricUnlockEnabled({required bool enabled}) {
    return _replace(state.copyWith(biometricUnlockEnabled: enabled));
  }

  Future<void> setPasscodeEnabled({required bool enabled}) {
    return _replace(state.copyWith(passcodeEnabled: enabled));
  }

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
    await guardRollback(next, () => _repository.save(next));
  }
}
