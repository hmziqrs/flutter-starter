import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

abstract final class ForuiThemeFactory {
  static const scriptFontFamilies = <String>['Noto Sans Arabic', 'Noto Sans SC'];

  static FThemeData build({
    required Brightness brightness,
    required AppAccent accent,
    required double fontScale,
    required AppInteractionPolicy interactionPolicy,
  }) {
    final generatedTheme = switch (brightness) {
      Brightness.light => generated.lightTheme,
      Brightness.dark => generated.darkTheme,
    };
    final accentColors = _accentColors(brightness, accent);
    final destructiveForeground = brightness == Brightness.dark
        ? const Color(0xff3f0712)
        : generatedTheme.colors.destructiveForeground;
    final colors = generatedTheme.colors.copyWith(
      primary: accentColors.$1,
      primaryForeground: accentColors.$2,
      destructiveForeground: destructiveForeground,
      errorForeground: destructiveForeground,
    );
    final touch = interactionPolicy != AppInteractionPolicy.precisionPointer;
    final typography = _withScriptFallbacks(generatedTheme.typography).scale(
      sizeScalar: fontScale,
    );

    return FThemeData(
      debugLabel: '${accent.name} ${brightness.name} ${touch ? 'touch' : 'desktop'}',
      breakpoints: generatedTheme.breakpoints,
      colors: colors,
      typography: typography,
      icons: generatedTheme.icons,
      touch: touch,
    );
  }

  static FTypography _withScriptFallbacks(FTypography typography) {
    return typography.copyWith(
      display: _withScriptFallbacksForTypeface(typography.display),
      body: _withScriptFallbacksForTypeface(typography.body),
    );
  }

  static FTypeface _withScriptFallbacksForTypeface(FTypeface typeface) {
    TextStyle withFallbacks(TextStyle style) {
      return style.copyWith(fontFamilyFallback: scriptFontFamilies);
    }

    return FTypeface(
      fontFamily: typeface.fontFamily,
      fontFamilyFallback: scriptFontFamilies,
      xs3: withFallbacks(typeface.xs3),
      xs2: withFallbacks(typeface.xs2),
      xs: withFallbacks(typeface.xs),
      sm: withFallbacks(typeface.sm),
      md: withFallbacks(typeface.md),
      lg: withFallbacks(typeface.lg),
      xl: withFallbacks(typeface.xl),
      xl2: withFallbacks(typeface.xl2),
      xl3: withFallbacks(typeface.xl3),
      xl4: withFallbacks(typeface.xl4),
      xl5: withFallbacks(typeface.xl5),
      xl6: withFallbacks(typeface.xl6),
      xl7: withFallbacks(typeface.xl7),
      xl8: withFallbacks(typeface.xl8),
    );
  }

  static (Color, Color) _accentColors(Brightness brightness, AppAccent accent) {
    if (accent == AppAccent.neutral) {
      final colors = brightness == Brightness.light
          ? generated.lightTheme.colors
          : generated.darkTheme.colors;
      return (colors.primary, colors.primaryForeground);
    }

    return switch ((brightness, accent)) {
      (Brightness.light, AppAccent.green) => (const Color(0xff15803d), Colors.white),
      (Brightness.dark, AppAccent.green) => (
        const Color(0xff4ade80),
        const Color(0xff052e16),
      ),
      (Brightness.light, AppAccent.blue) => (const Color(0xff2563eb), Colors.white),
      (Brightness.dark, AppAccent.blue) => (
        const Color(0xff60a5fa),
        const Color(0xff0c1b33),
      ),
      (Brightness.light, AppAccent.amber) => (const Color(0xffb45309), Colors.white),
      (Brightness.dark, AppAccent.amber) => (
        const Color(0xfffbbf24),
        const Color(0xff2e2100),
      ),
      (Brightness.light, AppAccent.rose) => (const Color(0xffbe123c), Colors.white),
      (Brightness.dark, AppAccent.rose) => (
        const Color(0xfffb7185),
        const Color(0xff3f0712),
      ),
      (Brightness.light, AppAccent.violet) => (const Color(0xff7c3aed), Colors.white),
      (Brightness.dark, AppAccent.violet) => (
        const Color(0xffa78bfa),
        const Color(0xff2e1065),
      ),
      (_, AppAccent.neutral) => throw StateError('Neutral uses generated theme colors.'),
    };
  }
}
