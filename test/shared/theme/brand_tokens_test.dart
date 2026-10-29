import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  FThemeData buildTheme(
    Brightness brightness,
    AppAccent accent, {
    String? fontFamily,
  }) => ForuiThemeFactory.build(
    brightness: brightness,
    accent: accent,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
    fontFamily: fontFamily,
  );

  group('AppBrandColors palette', () {
    test('carries the dark brand palette', () {
      const palette = AppBrandColors.dark;
      expect(palette.brightness, Brightness.dark);
      expect(palette.oxide, const Color(0xFFF38230));
      expect(palette.red, const Color(0xFFFF6467));
      expect(palette.yellow, const Color(0xFFE7B643));
      expect(palette.green, const Color(0xFF5DC879));
      expect(palette.teal, const Color(0xFF36C6B8));
      expect(palette.blue, const Color(0xFF5FA7FF));
      expect(palette.purple, const Color(0xFFB58BF9));
      expect(palette.pink, const Color(0xFFF079B6));
      expect(palette.onOrange, const Color(0xFF0A0A0A));
      expect(palette.line, const Color(0x38FAFAFA));
      expect(palette.markSquare, const Color(0xFFF38230));
    });

    test('carries the light brand palette', () {
      const palette = AppBrandColors.light;
      expect(palette.brightness, Brightness.light);
      expect(palette.oxide, const Color(0xFFAA530A));
      expect(palette.red, const Color(0xFFCD1622));
      expect(palette.yellow, const Color(0xFF906106));
      expect(palette.green, const Color(0xFF017B37));
      expect(palette.teal, const Color(0xFF04786E));
      expect(palette.blue, const Color(0xFF0069CD));
      expect(palette.purple, const Color(0xFF864AD2));
      expect(palette.pink, const Color(0xFFBC3181));
      expect(palette.onOrange, const Color(0xFFFFFFFF));
      expect(palette.line, const Color(0x380A0A0A));
      expect(palette.markSquare, const Color(0xFFF38230));
    });

    test('keeps the mark square bright orange in both modes', () {
      expect(AppBrandColors.light.markSquare, AppBrandColors.dark.markSquare);
    });

    test('maps status roles to their supporting colors', () {
      const palette = AppBrandColors.light;
      expect(palette.success, palette.green);
      expect(palette.warning, palette.yellow);
      expect(palette.info, palette.blue);
      expect(palette.destructive, palette.red);
      expect(palette.roleColor(AppStatusRole.success), palette.green);
      expect(palette.roleColor(AppStatusRole.warning), palette.yellow);
      expect(palette.roleColor(AppStatusRole.info), palette.blue);
      expect(palette.roleColor(AppStatusRole.destructive), palette.red);
      expect(palette.roleColor(AppStatusRole.neutral), isNull);
    });

    test('supports copyWith, equality and lerp', () {
      expect(AppBrandColors.light, AppBrandColors.light);
      expect(AppBrandColors.light.hashCode, AppBrandColors.light.hashCode);
      expect(AppBrandColors.light, isNot(AppBrandColors.dark));

      final copied = AppBrandColors.dark.copyWith(oxide: const Color(0xFF123456));
      expect(copied.oxide, const Color(0xFF123456));
      expect(copied.green, AppBrandColors.dark.green);
      expect(copied.brightness, Brightness.dark);
      expect(copied, isNot(AppBrandColors.dark));

      expect(AppBrandColors.light.lerp(null, 0.5), AppBrandColors.light);
      expect(AppBrandColors.light.lerp(AppBrandColors.dark, 0), AppBrandColors.light);
      expect(AppBrandColors.light.lerp(AppBrandColors.dark, 1), AppBrandColors.dark);
    });

    test('resolves the palette for a brightness', () {
      expect(AppBrandColors.forBrightness(Brightness.dark), AppBrandColors.dark);
      expect(AppBrandColors.forBrightness(Brightness.light), AppBrandColors.light);
    });
  });

  group('oxide accent default', () {
    test('defaults fresh settings to the oxide accent', () {
      expect(const SettingsState.defaults().accent, AppAccent.oxide);
    });

    test('applies the oxide accent colors to the theme', () {
      final light = buildTheme(Brightness.light, AppAccent.oxide);
      expect(light.colors.primary, const Color(0xFFAA530A));
      expect(light.colors.primaryForeground, const Color(0xFFFFFFFF));

      final dark = buildTheme(Brightness.dark, AppAccent.oxide);
      expect(dark.colors.primary, const Color(0xFFF38230));
      expect(dark.colors.primaryForeground, const Color(0xFF0A0A0A));
    });

    test('points every other accent at its brand palette token', () {
      final neutralLight = buildTheme(Brightness.light, AppAccent.neutral);
      expect(neutralLight.colors.primary, generated.lightColors.primary);

      final green = buildTheme(Brightness.dark, AppAccent.green);
      expect(green.colors.primary, AppBrandColors.dark.green);
      expect(green.colors.primaryForeground, AppBrandColors.dark.onOrange);

      final blue = buildTheme(Brightness.light, AppAccent.blue);
      expect(blue.colors.primary, AppBrandColors.light.blue);
      expect(blue.colors.primaryForeground, AppBrandColors.light.onOrange);

      final amber = buildTheme(Brightness.dark, AppAccent.amber);
      expect(amber.colors.primary, AppBrandColors.dark.yellow);

      final rose = buildTheme(Brightness.light, AppAccent.rose);
      expect(rose.colors.primary, AppBrandColors.light.red);

      final violet = buildTheme(Brightness.dark, AppAccent.violet);
      expect(violet.colors.primary, AppBrandColors.dark.purple);
    });
  });

  group('brand typography', () {
    test('resolves Onest as the default family with script fallbacks', () {
      final theme = buildTheme(Brightness.light, AppAccent.oxide);
      expect(theme.typography.body.fontFamily, 'Onest');
      expect(theme.typography.display.fontFamily, 'Onest');
      expect(theme.typography.body.md.fontFamily, 'Onest');
      expect(theme.typography.body.md.fontFamilyFallback, ForuiThemeFactory.scriptFontFamilies);
      expect(theme.typography.display.md.fontFamilyFallback, ForuiThemeFactory.scriptFontFamilies);
    });

    test('honors the fontFamily setting override', () {
      final overridden = buildTheme(
        Brightness.light,
        AppAccent.oxide,
        fontFamily: 'JetBrains Mono',
      );
      expect(overridden.typography.body.md.fontFamily, 'JetBrains Mono');
      expect(overridden.typography.display.md.fontFamily, 'JetBrains Mono');
    });

    test('sets display weight to 500 and body weight to 400', () {
      final theme = buildTheme(Brightness.dark, AppAccent.oxide);
      expect(theme.typography.display.md.fontWeight, FontWeight.w500);
      expect(theme.typography.body.md.fontWeight, FontWeight.w400);
    });
  });

  group('brand theme extension', () {
    test('attaches the matching palette to built themes', () {
      final light = buildTheme(Brightness.light, AppAccent.oxide);
      expect(light.extension<AppBrandColors>(), AppBrandColors.light);
      expect(light.brand, AppBrandColors.light);

      final dark = buildTheme(Brightness.dark, AppAccent.oxide);
      expect(dark.extension<AppBrandColors>(), AppBrandColors.dark);
      expect(dark.brand, AppBrandColors.dark);
    });

    test('falls back to the brightness palette without an attached extension', () {
      expect(FThemeData(colors: generated.lightColors, touch: true).brand, AppBrandColors.light);
      expect(FThemeData(colors: generated.darkColors, touch: true).brand, AppBrandColors.dark);
    });
  });

  group('brand neutrals', () {
    test('nudges light muted foreground to the AA-tuned brand value', () {
      final light = buildTheme(Brightness.light, AppAccent.oxide);
      expect(light.colors.mutedForeground, const Color(0xFF6F6F6F));

      final dark = buildTheme(Brightness.dark, AppAccent.oxide);
      expect(dark.colors.mutedForeground, const Color(0xFFA1A1A1));
    });
  });
}
