import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';

void main() {
  group('AppTextPreset.toSettings', () {
    test('maps every preset to a (fontScale, fontFamily) tuple', () {
      for (final preset in AppTextPreset.values) {
        final settings = preset.toSettings();
        expect(settings.fontScale, greaterThanOrEqualTo(SettingsState.minimumFontScale));
        expect(settings.fontScale, lessThanOrEqualTo(SettingsState.maximumFontScale));
      }
    });

    test('comfortable is the default-scale, default-font baseline', () {
      const settings = AppTextPreset.comfortable;
      final resolved = settings.toSettings();
      expect(resolved.fontScale, 1);
      expect(resolved.fontFamily, isNull);
    });

    test('large stays inside the [0.85, 1.6] font-scale clamp', () {
      final resolved = AppTextPreset.large.toSettings();
      expect(resolved.fontScale, greaterThan(1));
      expect(
        resolved.fontScale,
        lessThanOrEqualTo(SettingsState.maximumFontScale),
        reason: 'large preset must not bypass the font-scale clamp',
      );
      expect(resolved.fontFamily, isNull);
    });

    test('dyslexia applies the optional Latin font family and a readable scale', () {
      final resolved = AppTextPreset.dyslexia.toSettings();
      expect(resolved.fontScale, greaterThan(1));
      expect(resolved.fontScale, lessThanOrEqualTo(SettingsState.maximumFontScale));
      expect(resolved.fontFamily, AppTextPreset.dyslexiaFontFamily);
    });

    test('dyslexia font family is the documented placeholder (asset optional)', () {
      expect(AppTextPreset.dyslexiaFontFamily, 'OpenDyslexic');
    });

    test('AppTextPresetSettings value semantics', () {
      const a = AppTextPresetSettings(fontScale: 1.3);
      const b = AppTextPresetSettings(fontScale: 1.3);
      const c = AppTextPresetSettings(fontScale: 1.3, fontFamily: 'OpenDyslexic');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
