import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

abstract final class ForuiThemeFactory {
  /// Brand typeface (BRAND.md section 5): Onest for everything people read.
  static const String defaultFontFamily = 'Onest';

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
    double spacingScaleFactor = 1,
    double radiusScaleFactor = 1,
    AppPresentationPolicy? presentationPolicy,
  }) {
    if (!responsiveFontScale.isFinite || responsiveFontScale <= 0) {
      throw ArgumentError.value(
        responsiveFontScale,
        'responsiveFontScale',
        'Responsive font scale must be finite and greater than zero.',
      );
    }
    if (!spacingScaleFactor.isFinite || spacingScaleFactor <= 0) {
      throw ArgumentError.value(
        spacingScaleFactor,
        'spacingScaleFactor',
        'Spacing scale factor must be finite and greater than zero.',
      );
    }
    if (!radiusScaleFactor.isFinite || radiusScaleFactor < 0) {
      throw ArgumentError.value(
        radiusScaleFactor,
        'radiusScaleFactor',
        'Radius scale factor must be finite and non-negative.',
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
      // Brand neutral: the AA-tuned light muted-foreground (#6F6F6F, BRAND.md
      // section 4); the dark generated value already matches the brand (#A1A1A1).
      mutedForeground: brightness == Brightness.light ? const Color(0xFF6F6F6F) : null,
      destructiveForeground: destructiveForeground,
      errorForeground: destructiveForeground,
    );
    final resolvedPresentationPolicy =
        presentationPolicy ??
        AppPresentationPolicy(
          viewingEnvironment: AppViewingEnvironment.nearField,
          interactionPolicy: interactionPolicy,
        );
    final resolvedTokens = AppPresentationTokens.resolve(
      policy: resolvedPresentationPolicy,
      focusColor: colors.primary,
    );
    // Spacing density scales whitespace tokens only; touch-target floors
    // (controlMinHeight, focusTargetMinSize) must stay at their a11y minimums.
    final presentationTokens = resolvedTokens.copyWith(
      spacingScale: resolvedTokens.spacingScale * spacingScaleFactor,
      cardPadding: resolvedTokens.cardPadding * spacingScaleFactor,
      cardGap: resolvedTokens.cardGap * spacingScaleFactor,
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
    final inheritedStyle = FStyle.inherit(
      colors: colors,
      typography: typography,
      touch: touch,
    );
    final borderRadius = const FBorderRadius().scale(radiusScaleFactor);
    final style = inheritedStyle.copyWith(
      borderRadius: borderRadius,
      focusedOutlineStyle: inheritedStyle.focusedOutlineStyle.copyWith(
        borderRadius: borderRadius.md,
      ),
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
    final textFieldStyles = _brandTextFieldStyles(
      FTextFieldSizeStyles.inherit(
        colors: colors,
        typography: typography,
        style: style,
        touch: touch,
      ),
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
      textFieldStyles: textFieldStyles,
      extensions: [presentationTokens, AppBrandColors.forBrightness(brightness)],
    );
  }

  /// Brand text field recipe (BRAND.md s9): `shadow-none dark:bg-transparent`
  /// — the field is a line, no fill. The ForUI inherit paints the card color
  /// behind the input, which reads as a solid grey box in dark mode; both
  /// modes get a transparent fill and keep the inherit's line border.
  static FTextFieldSizeStyles _brandTextFieldStyles(FTextFieldSizeStyles styles) {
    return FTextFieldSizeStyles(
      FVariants.raw(_lineOnlyFieldFill(styles.base), {
        for (final MapEntry(key: constraint, :value) in styles.variants.entries)
          constraint: _lineOnlyFieldFill(value),
      }),
    );
  }

  static FTextFieldStyle _lineOnlyFieldFill(FTextFieldStyle style) {
    return style.copyWith(
      color: FVariants(Colors.transparent, variants: const {}),
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
    // Brand weights (BRAND.md section 5): headings 500, body 400, never above
    // 600. Onest is the default family; the user's fontFamily setting wins.
    return typography.copyWith(
      display: _buildTypeface(
        typography.display,
        tokens: _displayTokens,
        sizeScalar: displaySizeScalar,
        weight: FontWeight.w500,
        fontFamily: fontFamily,
      ),
      body: _buildTypeface(
        typography.body,
        tokens: _bodyTokens,
        sizeScalar: bodySizeScalar,
        weight: FontWeight.w400,
        fontFamily: fontFamily,
      ),
    );
  }

  static FTypeface _buildTypeface(
    FTypeface typeface, {
    required List<({double size, double height})> tokens,
    required double sizeScalar,
    required FontWeight weight,
    String? fontFamily,
  }) {
    final resolvedFontFamily = fontFamily ?? defaultFontFamily;
    TextStyle token(TextStyle style, int index) {
      final token = tokens[index];
      return style.copyWith(
        fontFamily: resolvedFontFamily,
        fontFamilyFallback: scriptFontFamilies,
        fontSize: token.size * sizeScalar,
        fontWeight: weight,
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

    // Every accent points at a brand palette token (BRAND.md section 4):
    // picking an accent re-points --primary at that palette color, so a
    // "green" accent is the app's own success green, amber is brand yellow,
    // rose is brand red and violet is brand purple. The on-color follows the
    // brand's primary-foreground rule: white on light shades, near-black
    // (on-orange) on dark shades.
    final brand = AppBrandColors.forBrightness(brightness);
    return switch (accent) {
      AppAccent.oxide => (brand.oxide, brand.onOrange),
      AppAccent.green => (brand.green, brand.onOrange),
      AppAccent.blue => (brand.blue, brand.onOrange),
      AppAccent.amber => (brand.yellow, brand.onOrange),
      AppAccent.rose => (brand.red, brand.onOrange),
      AppAccent.violet => (brand.purple, brand.onOrange),
      AppAccent.neutral => throw StateError('Neutral uses generated theme colors.'),
    };
  }
}
