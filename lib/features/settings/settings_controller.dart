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

  /// Applies a named accessibility text preset. Resolves the preset to its
  /// clamped `(fontScale, fontFamily)` tuple and updates both `textPreset` and
  /// `fontScale` atomically; `fontFamily` is derived from `textPreset` on
  /// `SettingsState` so it tracks the preset without a separate field. The
  /// manual [setFontScale] slider is left untouched by this method and does not
  /// reset the preset label, so a user can fine-tune the scale after picking a
  /// preset. Optimistic update + rollback via [_replace].
  Future<void> setTextPreset(AppTextPreset preset) {
    final resolved = preset.toSettings();
    return _replace(state.copyWith(textPreset: preset, fontScale: resolved.fontScale));
  }

  /// Toggles the haptics opt-in. Default-on; each call site also gates on
  /// `MediaQuery.disableAnimationsOf`. Persisted through the repository like
  /// every other setting. Optimistic update + rollback via [_replace].
  Future<void> setHapticsEnabled({required bool enabled}) {
    return _replace(state.copyWith(hapticsEnabled: enabled));
  }

  /// Marks first-launch onboarding complete with an optimistic in-memory write
  /// through [SettingsRepository.save]. The synchronous `state =` inside
  /// [_replace] happens before the first await, so a caller that fires this and
  /// then navigates with `context.goNamed(home)` on the same tick is observable
  /// to the onboarding redirect's live `container.read(...)` lookup — the
  /// redirect never sees a stale `false`. Persistence failure rolls the flag
  /// back to its previous value and rethrows.
  Future<void> markOnboardingComplete() {
    return _replace(state.copyWith(hasCompletedOnboarding: true));
  }

  /// Toggles the biometric-unlock opt-in. Read by the C5 redirect alongside the
  /// biometric lock state; persisted through the repository like every other
  /// setting. Optimistic update + rollback via [_replace].
  Future<void> setBiometricUnlockEnabled({required bool enabled}) {
    return _replace(state.copyWith(biometricUnlockEnabled: enabled));
  }

  /// Toggles the passcode opt-in. Read by the C5 PASSCODE redirect block
  /// alongside PasscodeState. Turning this ON pushes the passcode-setup route
  /// (the user must configure a passcode before the gate arms); turning it OFF
  /// disables the passcode via the controller and clears the gate. Optimistic
  /// update + rollback via [_replace].
  Future<void> setPasscodeEnabled({required bool enabled}) {
    return _replace(state.copyWith(passcodeEnabled: enabled));
  }

  /// Sets the idle auto-lock delay in seconds (0 = idle locking off). Negatives
  /// are clamped to 0. Only meaningful when [SettingsState.passcodeEnabled] is
  /// true. Optimistic update + rollback via [_replace].
  Future<void> setAutoLockDelaySeconds(int seconds) {
    return _replace(state.copyWith(autoLockDelaySeconds: seconds < 0 ? 0 : seconds));
  }

  /// Toggles whether the app re-locks when backgrounded. Only meaningful when
  /// [SettingsState.passcodeEnabled] is true. Optimistic update + rollback via
  /// [_replace].
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
