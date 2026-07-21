import 'package:flutter/foundation.dart';
import 'package:starter/i18n/translations.g.dart';

enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

@immutable
final class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.accent,
    required this.fontScale,
    required this.localeOverride,
  });

  const SettingsState.defaults()
    : themeMode = AppThemeMode.system,
      accent = AppAccent.neutral,
      fontScale = 1,
      localeOverride = null;

  static const minimumFontScale = 0.85;
  static const maximumFontScale = 1.6;
  static const fontScaleStep = 0.05;

  final AppThemeMode themeMode;
  final AppAccent accent;
  final double fontScale;
  final AppLocale? localeOverride;

  SettingsState copyWith({
    AppThemeMode? themeMode,
    AppAccent? accent,
    double? fontScale,
    AppLocale? localeOverride,
    bool followSystemLocale = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      fontScale: fontScale ?? this.fontScale,
      localeOverride: followSystemLocale ? null : (localeOverride ?? this.localeOverride),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SettingsState &&
            themeMode == other.themeMode &&
            accent == other.accent &&
            fontScale == other.fontScale &&
            localeOverride == other.localeOverride;
  }

  @override
  int get hashCode => Object.hash(themeMode, accent, fontScale, localeOverride);
}
