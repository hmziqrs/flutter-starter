import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/i18n/translations.g.dart';

final class SettingsRepository {
  const SettingsRepository(this._store);

  static const themeModeKey = 'appearance.theme_mode';
  static const accentKey = 'appearance.accent';
  static const fontScaleKey = 'appearance.font_scale';
  static const localeKey = 'localization.locale';
  static const persistedKeys = <String>[
    themeModeKey,
    accentKey,
    fontScaleKey,
    localeKey,
  ];

  final SettingsStore _store;

  Future<SettingsState> load() async {
    try {
      final values = await Future.wait<String?>([
        _store.readString(themeModeKey),
        _store.readString(accentKey),
        _store.readString(fontScaleKey),
        _store.readString(localeKey),
      ]);

      return SettingsState(
        themeMode: _enumByName(AppThemeMode.values, values[0]) ?? AppThemeMode.system,
        accent: _enumByName(AppAccent.values, values[1]) ?? AppAccent.neutral,
        fontScale: _parseFontScale(values[2]),
        localeOverride: _parseLocale(values[3]),
      );
    } on SettingsStoreException catch (error) {
      throw SettingsFailure.read(error.operation);
    }
  }

  Future<void> save(SettingsState state) async {
    try {
      await Future.wait<void>([
        _store.writeString(themeModeKey, state.themeMode.name),
        _store.writeString(accentKey, state.accent.name),
        _store.writeString(fontScaleKey, state.fontScale.toStringAsFixed(2)),
        switch (state.localeOverride) {
          final locale? => _store.writeString(localeKey, locale.languageTag),
          null => _store.remove(localeKey),
        },
      ]);
    } on SettingsStoreException catch (error) {
      throw SettingsFailure.write(error.operation);
    }
  }

  static T? _enumByName<T extends Enum>(Iterable<T> values, String? savedValue) {
    if (savedValue == null) {
      return null;
    }

    for (final value in values) {
      if (value.name == savedValue) {
        return value;
      }
    }
    return null;
  }

  static double _parseFontScale(String? savedValue) {
    final parsed = double.tryParse(savedValue ?? '');
    if (parsed == null ||
        parsed < SettingsState.minimumFontScale ||
        parsed > SettingsState.maximumFontScale) {
      return const SettingsState.defaults().fontScale;
    }
    return parsed;
  }

  static AppLocale? _parseLocale(String? savedValue) {
    if (savedValue == null || !AppLocaleUtils.supportedLocalesRaw.contains(savedValue)) {
      return null;
    }
    return AppLocaleUtils.parse(savedValue);
  }
}

final class SettingsFailure implements Exception {
  const SettingsFailure._(this.operation);

  factory SettingsFailure.read(String operation) => SettingsFailure._('read:$operation');

  factory SettingsFailure.write(String operation) => SettingsFailure._('write:$operation');

  final String operation;

  @override
  String toString() => 'SettingsFailure: $operation';
}
