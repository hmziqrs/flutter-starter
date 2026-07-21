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
