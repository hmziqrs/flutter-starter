import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/preferences/bool_codec.dart';

final class SettingsRepository {
  const SettingsRepository(this._store);

  static const themeModeKey = 'appearance.theme_mode';
  static const accentKey = 'appearance.accent';
  static const fontScaleKey = 'appearance.font_scale';
  static const textPresetKey = 'appearance.text_preset';
  static const spacingKey = 'appearance.spacing';
  static const radiusKey = 'appearance.radius';
  static const localeKey = 'localization.locale';
  static const onboardingKey = 'onboarding.completed';
  static const biometricUnlockKey = 'security.biometric_unlock_enabled';
  static const hapticsEnabledKey = 'appearance.haptics_enabled';
  static const passcodeEnabledKey = 'security.passcode_enabled';
  static const autoLockDelayKey = 'security.auto_lock_delay_seconds';
  static const lockOnBackgroundKey = 'security.lock_on_background';
  static const persistedKeys = <String>[
    themeModeKey,
    accentKey,
    fontScaleKey,
    textPresetKey,
    spacingKey,
    radiusKey,
    localeKey,
    onboardingKey,
    biometricUnlockKey,
    hapticsEnabledKey,
    passcodeEnabledKey,
    autoLockDelayKey,
    lockOnBackgroundKey,
  ];

  final SettingsStore _store;

  Future<SettingsState> load() async {
    try {
      final values = await Future.wait<String?>([
        _store.readString(themeModeKey),
        _store.readString(accentKey),
        _store.readString(fontScaleKey),
        _store.readString(textPresetKey),
        _store.readString(spacingKey),
        _store.readString(radiusKey),
        _store.readString(localeKey),
        _store.readString(onboardingKey),
        _store.readString(biometricUnlockKey),
        _store.readString(hapticsEnabledKey),
        _store.readString(passcodeEnabledKey),
        _store.readString(autoLockDelayKey),
        _store.readString(lockOnBackgroundKey),
      ]);

      final textPreset = _enumByName(AppTextPreset.values, values[3]) ?? AppTextPreset.comfortable;
      return SettingsState(
        themeMode: _enumByName(AppThemeMode.values, values[0]) ?? AppThemeMode.system,
        accent: _enumByName(AppAccent.values, values[1]) ?? AppAccent.neutral,
        fontScale: _parseFontScale(values[2]),
        textPreset: textPreset,
        spacingVariant:
            _enumByName(AppSpacingVariant.values, values[4]) ?? AppSpacingVariant.standard,
        radiusVariant: _enumByName(AppRadiusVariant.values, values[5]) ?? AppRadiusVariant.rounded,
        localeOverride: _parseLocale(values[6]),
        hasCompletedOnboarding: values[7] == 'true',
        biometricUnlockEnabled: values[8] == 'true',
        hapticsEnabled: values[9] != 'false',
        passcodeEnabled: values[10] == 'true',
        autoLockDelaySeconds: _parseAutoLockDelay(values[11]),
        lockOnBackground: values[12] == 'true',
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
        _store.writeString(textPresetKey, state.textPreset.name),
        _store.writeString(spacingKey, state.spacingVariant.name),
        _store.writeString(radiusKey, state.radiusVariant.name),
        switch (state.localeOverride) {
          final locale? => _store.writeString(localeKey, locale.languageTag),
          null => _store.remove(localeKey),
        },
        _store.writeBool(onboardingKey, value: state.hasCompletedOnboarding),
        _store.writeBool(biometricUnlockKey, value: state.biometricUnlockEnabled),
        _store.writeBool(hapticsEnabledKey, value: state.hapticsEnabled, invert: true),
        _store.writeBool(passcodeEnabledKey, value: state.passcodeEnabled),
        switch (state.autoLockDelaySeconds) {
          0 => _store.remove(autoLockDelayKey),
          final seconds => _store.writeString(autoLockDelayKey, seconds.toString()),
        },
        _store.writeBool(lockOnBackgroundKey, value: state.lockOnBackground),
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

  static int _parseAutoLockDelay(String? savedValue) {
    final parsed = int.tryParse(savedValue ?? '');
    if (parsed == null || parsed < 0) {
      return const SettingsState.defaults().autoLockDelaySeconds;
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
