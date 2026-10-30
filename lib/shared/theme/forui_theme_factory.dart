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

typedef _ButtonSizeMetrics = ({
  double height,
  double horizontalPadding,
  double gap,
  double iconSize,
});

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
      // Brand motion rule (BRAND.md s8): hover/press/focus feedback is COLOR
      // ONLY — never scale/translate/rotate. ForUI's default tappable motion
      // bounces widgets to 0.97 on press (FTappableMotion.defaultBounceTween),
      // so the shared style pins FTappableMotion.none app-wide, the same way
      // ForUI's own radio, checkbox and breadcrumb widgets do.
      tappableStyle: inheritedStyle.tappableStyle.copyWith(motion: FTappableMotion.none),
      focusedOutlineStyle: inheritedStyle.focusedOutlineStyle.copyWith(
        borderRadius: borderRadius.md,
      ),
    );
    // Brand metrics in EVERY input model: the touch policy no longer raises
    // button heights to control floors — the brand kit's buttons are the same
    // 24/32/36/40 on a phone as on a desktop (hit comfort comes from the
    // layout's own spacing, not from inflating the control).
    final buttonStyles = _brandButtonStyles(
      FButtonStyles.inherit(
        colors: colors,
        typography: typography,
        style: style,
        touch: touch,
      ),
      radius: borderRadius.sm,
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

  /// Brand button metrics, from the brand kit's `ui/button/button.svelte`:
  /// md (default) h-9 px-2.5 gap-1.5, sm h-8 px-2.5 gap-1, lg h-10 px-2.5
  /// gap-1.5, xs h-6 px-2 gap-1 — icon buttons square at the size height,
  /// rounded-md, text-sm (14px) font-medium (w500, already applied by the
  /// ForUI inherit over this factory's w400 body typeface). In-button svg
  /// glyphs are pinned at size-4 (16px), size-3 (12px) on the xs size
  /// variant, for label and icon-only buttons alike — ForUI instead sizes
  /// label-button icons at the label font size (14) and icon-only buttons at
  /// body.sm/md/lg, so both icon styles are re-pinned here. The kit's
  /// `rounded-md` resolves to --radius-md = calc(--radius(10px) - 2px) = 8px
  /// (BRAND.md sections 1 and 3), which is the ForUI sm token — not the 10px
  /// md token the inherit paints on md/sm/lg — so the decoration is
  /// re-surfaced at that radius for every size.
  static final Map<FButtonSizeVariant, _ButtonSizeMetrics> _buttonMetrics = {
    FButtonSizeVariant.xs: (height: 24, horizontalPadding: 8, gap: 4, iconSize: 12),
    FButtonSizeVariant.sm: (height: 32, horizontalPadding: 10, gap: 4, iconSize: 16),
    FButtonSizeVariant.md: (height: 36, horizontalPadding: 10, gap: 6, iconSize: 16),
    FButtonSizeVariant.lg: (height: 40, horizontalPadding: 10, gap: 6, iconSize: 16),
  };

  static FVariants<FButtonVariantConstraint, FButtonVariant, FButtonSizeStyles, FButtonSizesDelta>
  _brandButtonStyles(FButtonStyles styles, {required BorderRadiusGeometry radius}) {
    return FVariants.raw(
      _brandButtonSizeStyles(styles.base, radius: radius),
      {
        for (final MapEntry(key: constraint, :value) in styles.variants.entries)
          constraint: _brandButtonSizeStyles(value, radius: radius),
      },
    );
  }

  static FButtonSizeStyles _brandButtonSizeStyles(
    FButtonSizeStyles styles, {
    required BorderRadiusGeometry radius,
  }) {
    return FButtonSizeStyles(
      FVariants.raw(
        _brandButtonStyle(
          styles.base,
          metrics: _buttonMetrics[FButtonSizeVariant.md]!,
          radius: radius,
        ),
        {
          for (final MapEntry(key: constraint, :value) in styles.variants.entries)
            constraint: _brandButtonStyle(
              value,
              metrics: _sizeMetrics(constraint),
              radius: radius,
            ),
        },
      ),
    );
  }

  /// The size style's base is md; variant entries are keyed by their size
  /// constraint, so the brand metrics follow the size the button resolves to.
  static _ButtonSizeMetrics _sizeMetrics(FButtonSizeVariantConstraint constraint) {
    for (final MapEntry(key: variant, :value) in _buttonMetrics.entries) {
      if (constraint.satisfiedBy(<FVariant>{variant})) {
        return value;
      }
    }
    return _buttonMetrics[FButtonSizeVariant.md]!;
  }

  static FButtonStyle _brandButtonStyle(
    FButtonStyle style, {
    required _ButtonSizeMetrics metrics,
    required BorderRadiusGeometry radius,
  }) {
    final content = style.contentStyle;
    // The ForUI inherit pins the button label's line height to its font size
    // (height: 1). The tallest in-button glyph sets the content height: the
    // label, or the pinned svg icon (16px, 12px on xs) when one rides along,
    // so a label+icon button keeps the same brand box as a label-only one.
    // Padding the content with half the brand height's slack centers it
    // exactly — 10/8/12/6 vertically at the default sizes. Glyphs scaled past
    // the brand height grow the button instead of being clipped, mirroring
    // the CSS fixed-height button's overflow.
    final fontSize = content.textStyle.base.fontSize ?? 14;
    final contentSize = math.max(fontSize, metrics.iconSize);
    final halfSlack = (metrics.height - contentSize) / 2;
    final verticalPadding = halfSlack > 0 ? halfSlack : 0.0;
    // Icon-only buttons carry a tight square from ForUI's own touch table.
    final isIconOnly = content.constraints.hasTightWidth && content.constraints.maxWidth.isFinite;

    return style.copyWith(
      decoration: _brandButtonDecoration(style.decoration, radius: radius),
      contentStyle: FButtonContentStyle(
        textStyle: content.textStyle,
        iconStyle: _brandIconSize(content.iconStyle, size: metrics.iconSize),
        circularProgressStyle: content.circularProgressStyle,
        // The brand box renders exactly in every input model (xs 24, sm 32,
        // md 36, lg 40) — no touch inflation. Re-square the tight icon-only
        // box at the brand size (copyWith cannot shrink a tight max).
        constraints: BoxConstraints(
          minWidth: metrics.height,
          maxWidth: isIconOnly ? metrics.height : content.constraints.maxWidth,
          minHeight: metrics.height,
          maxHeight: isIconOnly ? metrics.height : content.constraints.maxHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: verticalPadding,
        ),
        spacing: metrics.gap,
      ),
      iconContentStyle: FButtonIconContentStyle(
        iconStyle: _brandIconSize(style.iconContentStyle.iconStyle, size: metrics.iconSize),
        // Center the pinned glyph in the brand square: half the slack
        // between the square and the glyph on each side.
        padding: EdgeInsets.symmetric(horizontal: halfSlack, vertical: halfSlack),
        constraints: BoxConstraints(
          minWidth: metrics.height,
          maxWidth: metrics.height,
          minHeight: metrics.height,
          maxHeight: metrics.height,
        ),
      ),
    );
  }

  /// Re-pins every icon style state (base, disable) at the brand svg size,
  /// keeping the per-state colors the inherit already materialized.
  static FVariants<FTappableVariantConstraint, FTappableVariant, IconThemeData, IconThemeDataDelta>
  _brandIconSize(
    FVariants<FTappableVariantConstraint, FTappableVariant, IconThemeData, IconThemeDataDelta>
    icons, {
    required double size,
  }) {
    IconThemeData pin(IconThemeData value) => value.copyWith(size: size);

    return FVariants.raw(
      pin(icons.base),
      {
        for (final MapEntry(key: constraint, :value) in icons.variants.entries)
          constraint: pin(value),
      },
    );
  }

  /// Re-surfaces every decoration state (base, hover, press, disable, select)
  /// at the brand corner radius. The inherit paints md/sm/lg with ForUI's 10px
  /// md token; the brand's `rounded-md` is 8px, so the shape is swapped while
  /// the per-state colors the deltas already materialized are kept.
  static FVariants<FTappableVariantConstraint, FTappableVariant, Decoration, DecorationDelta>
  _brandButtonDecoration(
    FVariants<FTappableVariantConstraint, FTappableVariant, Decoration, DecorationDelta>
    decoration, {
    required BorderRadiusGeometry radius,
  }) {
    Decoration resurface(Decoration value) {
      final shapeDecoration = value as ShapeDecoration;
      final border = shapeDecoration.shape as RoundedSuperellipseBorder;
      // ShapeDecoration has no copyWith in Flutter 3.44.7: rebuild it with the
      // same fields, swapping only the shape's corner radius.
      return ShapeDecoration(
        color: shapeDecoration.color,
        image: shapeDecoration.image,
        gradient: shapeDecoration.gradient,
        shadows: shapeDecoration.shadows,
        shape: border.copyWith(borderRadius: radius),
      );
    }

    return FVariants.raw(
      resurface(decoration.base),
      {
        for (final MapEntry(key: constraint, :value) in decoration.variants.entries)
          constraint: resurface(value),
      },
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
