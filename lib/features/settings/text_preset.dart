import 'package:flutter/foundation.dart';

/// Named accessibility text presets. Each maps to a clamped `fontScale` and
/// an optional Latin-only `fontFamily`; non-Latin locales keep their bundled
/// Noto Sans fallback regardless of preset.
enum AppTextPreset {
  comfortable,
  large,
  dyslexia;

  AppTextPresetSettings toSettings() => switch (this) {
    AppTextPreset.comfortable => const AppTextPresetSettings(fontScale: 1),
    AppTextPreset.large => const AppTextPresetSettings(fontScale: _largeFontScale),
    AppTextPreset.dyslexia => const AppTextPresetSettings(
      fontScale: _dyslexiaFontScale,
      fontFamily: _dyslexiaFontFamily,
    ),
  };

  /// Placeholder family name; the theme factory falls back gracefully if the
  /// font asset isn't bundled.
  static const String dyslexiaFontFamily = _dyslexiaFontFamily;

  static const _largeFontScale = 1.3;
  static const _dyslexiaFontScale = 1.1;
  static const _dyslexiaFontFamily = 'OpenDyslexic';
}

/// Resolved preset settings; `fontFamily` is null except for dyslexia.
@immutable
final class AppTextPresetSettings {
  const AppTextPresetSettings({required this.fontScale, this.fontFamily});

  final double fontScale;
  final String? fontFamily;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppTextPresetSettings &&
            fontScale == other.fontScale &&
            fontFamily == other.fontFamily;
  }

  @override
  int get hashCode => Object.hash(fontScale, fontFamily);
}
