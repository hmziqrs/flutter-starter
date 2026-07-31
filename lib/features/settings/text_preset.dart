import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_preset.freezed.dart';

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

  static const String dyslexiaFontFamily = _dyslexiaFontFamily;

  static const _largeFontScale = 1.3;
  static const _dyslexiaFontScale = 1.1;
  static const _dyslexiaFontFamily = 'OpenDyslexic';
}

@freezed
abstract class AppTextPresetSettings with _$AppTextPresetSettings {
  const factory AppTextPresetSettings({required double fontScale, String? fontFamily}) =
      _AppTextPresetSettings;
}
