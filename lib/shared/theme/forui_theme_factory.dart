import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

abstract final class ForuiThemeFactory {
  static const scriptFontFamilies = <String>['Noto Sans Arabic', 'Noto Sans SC'];
  static const _displayTokens = <({double size, double height})>[
    (size: 10, height: 1.2),
    (size: 12, height: 1.2),
    (size: 14, height: 1.2),
    (size: 16, height: 1.25),
    (size: 18, height: 1.25),
    (size: 20, height: 1.2),
    (size: 24, height: 1.2),
    (size: 30, height: 1.15),
    (size: 36, height: 1.12),
    (size: 48, height: 1.1),
    (size: 60, height: 1.1),
    (size: 72, height: 1.1),
    (size: 96, height: 1.1),
    (size: 108, height: 1.1),
  ];
  static const _bodyTokens = <({double size, double height})>[
    (size: 10, height: 1.25),
    (size: 11, height: 1.25),
    (size: 12, height: 1.3),
    (size: 14, height: 1.35),
    (size: 16, height: 1.4),
    (size: 18, height: 1.45),
    (size: 20, height: 1.45),
    (size: 24, height: 1.35),
    (size: 30, height: 1.25),
    (size: 36, height: 1.2),
    (size: 48, height: 1.15),
    (size: 60, height: 1.15),
    (size: 72, height: 1.1),
    (size: 96, height: 1.1),
  ];

  static FThemeData build({
    required Brightness brightness,
    required AppAccent accent,
    required double fontScale,
    required AppInteractionPolicy interactionPolicy,
    String? fontFamily,
    double responsiveFontScale = 1,
    AppPresentationPolicy? presentationPolicy,
  }) {
    if (!responsiveFontScale.isFinite || responsiveFontScale <= 0) {
      throw ArgumentError.value(
        responsiveFontScale,
        'responsiveFontScale',
        'Responsive font scale must be finite and greater than zero.',
      );
    }

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
    final resolvedPresentationPolicy =
        presentationPolicy ??
        AppPresentationPolicy(
          viewingEnvironment: AppViewingEnvironment.nearField,
          interactionPolicy: interactionPolicy,
        );
    final presentationTokens = AppPresentationTokens.resolve(
      policy: resolvedPresentationPolicy,
      focusColor: colors.primary,
    );
    final touch = switch (interactionPolicy) {
      AppInteractionPolicy.precisionPointer => false,
      AppInteractionPolicy.touch ||
      AppInteractionPolicy.hybrid ||
      AppInteractionPolicy.remote ||
      AppInteractionPolicy.hybridRemote => true,
    };
    final typography = _buildTypography(
      generatedTheme.typography,
      bodySizeScalar: fontScale * responsiveFontScale * presentationTokens.bodyTypeScale,
      displaySizeScalar: fontScale * responsiveFontScale * presentationTokens.displayTypeScale,
      fontFamily: fontFamily,
    );
    final style = FStyle.inherit(
      colors: colors,
      typography: typography,
      touch: touch,
    );
    final buttonStyles = _balancedButtonStyles(
      FButtonStyles.inherit(
        colors: colors,
        typography: typography,
        style: style,
        touch: touch,
      ),
      minimumHeight: presentationTokens.controlMinHeight,
    );

    return FThemeData(
      debugLabel: '${accent.name} ${brightness.name} ${touch ? 'touch' : 'desktop'}',
      breakpoints: generatedTheme.breakpoints,
      colors: colors,
      typography: typography,
      icons: generatedTheme.icons,
      style: style,
      touch: touch,
      buttonStyles: buttonStyles,
      extensions: [presentationTokens],
    );
  }

  static FVariants<FButtonVariantConstraint, FButtonVariant, FButtonSizeStyles, FButtonSizesDelta>
  _balancedButtonStyles(
    FButtonStyles styles, {
    required double minimumHeight,
  }) {
    return FVariants.raw(
      _balancedButtonSizeStyles(styles.base, minimumHeight: minimumHeight),
      {
        for (final MapEntry(key: constraint, :value) in styles.variants.entries)
          constraint: _balancedButtonSizeStyles(
            value,
            minimumHeight: minimumHeight,
          ),
      },
    );
  }

  static FButtonSizeStyles _balancedButtonSizeStyles(
    FButtonSizeStyles styles, {
    required double minimumHeight,
  }) {
    return FButtonSizeStyles(
      FVariants.raw(
        _balancedButtonStyle(styles.base, minimumHeight: minimumHeight),
        {
          for (final MapEntry(key: constraint, :value) in styles.variants.entries)
            constraint: _balancedButtonStyle(
              value,
              minimumHeight: minimumHeight,
            ),
        },
      ),
    );
  }

  static FButtonStyle _balancedButtonStyle(
    FButtonStyle style, {
    required double minimumHeight,
  }) {
    final content = style.contentStyle;
    final resolvedPadding = content.padding.resolve(TextDirection.ltr);
    final fontSize = content.textStyle.base.fontSize ?? 14;
    final verticalPadding = (fontSize * 0.55).clamp(6.0, 10.0);

    return style.copyWith(
      contentStyle: FButtonContentStyle(
        textStyle: content.textStyle,
        iconStyle: content.iconStyle,
        circularProgressStyle: content.circularProgressStyle,
        constraints: content.constraints.copyWith(
          minHeight: math.max(content.constraints.minHeight, minimumHeight),
          maxHeight: math.max(content.constraints.maxHeight, minimumHeight),
        ),
        padding: EdgeInsets.fromLTRB(
          resolvedPadding.left,
          verticalPadding,
          resolvedPadding.right,
          verticalPadding,
        ),
        spacing: content.spacing,
      ),
    );
  }

  static FTypography _buildTypography(
    FTypography typography, {
    required double bodySizeScalar,
    required double displaySizeScalar,
    String? fontFamily,
  }) {
    return typography.copyWith(
      display: _buildTypeface(
        typography.display,
        tokens: _displayTokens,
        sizeScalar: displaySizeScalar,
        fontFamily: fontFamily,
      ),
      body: _buildTypeface(
        typography.body,
        tokens: _bodyTokens,
        sizeScalar: bodySizeScalar,
        fontFamily: fontFamily,
      ),
    );
  }

  static FTypeface _buildTypeface(
    FTypeface typeface, {
    required List<({double size, double height})> tokens,
    required double sizeScalar,
    String? fontFamily,
  }) {
    final resolvedFontFamily = fontFamily ?? typeface.fontFamily;
    TextStyle token(TextStyle style, int index) {
      final token = tokens[index];
      return style.copyWith(
        fontFamily: resolvedFontFamily,
        fontFamilyFallback: scriptFontFamilies,
        fontSize: token.size * sizeScalar,
        height: token.height,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    return FTypeface(
      fontFamily: resolvedFontFamily,
      fontFamilyFallback: scriptFontFamilies,
      xs3: token(typeface.xs3, 0),
      xs2: token(typeface.xs2, 1),
      xs: token(typeface.xs, 2),
      sm: token(typeface.sm, 3),
      md: token(typeface.md, 4),
      lg: token(typeface.lg, 5),
      xl: token(typeface.xl, 6),
      xl2: token(typeface.xl2, 7),
      xl3: token(typeface.xl3, 8),
      xl4: token(typeface.xl4, 9),
      xl5: token(typeface.xl5, 10),
      xl6: token(typeface.xl6, 11),
      xl7: token(typeface.xl7, 12),
      xl8: token(typeface.xl8, 13),
    );
  }

  static SystemUiOverlayStyle overlayStyle({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
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
