import 'package:flutter/foundation.dart';

/// Named accessibility text presets surfaced through the settings UI.
///
/// Each preset maps to a clamped `fontScale` (always inside the
/// `SettingsState.minimumFontScale .. maximumFontScale` range, so the
/// repository's `_parseFontScale` clamp never rejects a preset) and an
/// optional Latin-only `fontFamily` override. Non-Latin locales keep their
/// bundled Noto Sans Arabic / Noto Sans SC fallback via
/// `ForuiThemeFactory.scriptFontFamilies` — the dyslexia family is never
/// swapped wholesale (see feature spec Risks).
///
/// The enum is persisted by name through `SettingsRepository.textPresetKey`
/// (mirrors `themeMode`/`accent`); the resolved `(fontScale, fontFamily)`
/// tuple is applied to `SettingsState` by the controller's `setTextPreset`.
enum AppTextPreset {
  comfortable,
  large,
  dyslexia;

  /// Pure mapping from this preset to the `(fontScale, fontFamily)` tuple the
  /// controller applies to `SettingsState`. Exhaustive over [AppTextPreset];
  /// adding a new variant forces a branch here (strict analysis).
  AppTextPresetSettings toSettings() => switch (this) {
    AppTextPreset.comfortable => const AppTextPresetSettings(fontScale: 1),
    AppTextPreset.large => const AppTextPresetSettings(fontScale: _largeFontScale),
    AppTextPreset.dyslexia => const AppTextPresetSettings(
      fontScale: _dyslexiaFontScale,
      fontFamily: _dyslexiaFontFamily,
    ),
  };

  /// The optional Latin-only dyslexia family. Bundled as an asset only when a
  /// consumer ships the font (see feature spec Risks / native notes). Until
  /// then the dyslexia preset still raises the font scale and the value is a
  /// documented placeholder the theme factory resolves through
  /// `fontFamilyFallback` when the asset is absent.
  static const String dyslexiaFontFamily = _dyslexiaFontFamily;

  static const _largeFontScale = 1.3;
  static const _dyslexiaFontScale = 1.1;
  static const _dyslexiaFontFamily = 'OpenDyslexic';
}

/// Immutable resolved preset settings. `fontFamily` is `null` for the
/// comfortable and large presets (use the bundled Noto Sans families) and the
/// optional Latin dyslexia family for the dyslexia preset.
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
