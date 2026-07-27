import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
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
