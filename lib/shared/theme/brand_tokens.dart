import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Semantic status roles carried by the brand palette.
///
/// Neutral has no brand color; resolve it from the ForUI theme's
/// secondary/muted tokens so grey stays the absence of meaning.
enum AppStatusRole { neutral, success, warning, info, destructive }

/// The hmziq brand palette (BRAND.md section 4) as a theme extension.
///
/// One instance per [Brightness]; attach [light] or [dark] to the matching
/// `FThemeData` so widgets can resolve brand colors without hex literals.
/// Oxide orange is the primary and the only color ever used as a solid fill
/// behind text; the seven supporting colors appear as text, icons, dots,
/// lines and soft fills, and the status roles point at them by meaning.
@immutable
final class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.brightness,
    required this.oxide,
    required this.red,
    required this.yellow,
    required this.green,
    required this.teal,
    required this.blue,
    required this.purple,
    required this.pink,
    required this.onOrange,
    required this.line,
    required this.markSquare,
  });

  /// Dark palette (default mode): bright shades tuned for AA on `#0A0A0A`.
  static const AppBrandColors dark = AppBrandColors(
    brightness: Brightness.dark,
    oxide: Color(0xFFF38230),
    red: Color(0xFFFF6467),
    yellow: Color(0xFFE7B643),
    green: Color(0xFF5DC879),
    teal: Color(0xFF36C6B8),
    blue: Color(0xFF5FA7FF),
    purple: Color(0xFFB58BF9),
    pink: Color(0xFFF079B6),
    onOrange: Color(0xFF0A0A0A),
    line: Color(0x38FAFAFA),
    markSquare: Color(0xFFF38230),
  );

  /// Light palette: deep shades tuned for AA on `#FFFFFF`.
  static const AppBrandColors light = AppBrandColors(
    brightness: Brightness.light,
    oxide: Color(0xFFAA530A),
    red: Color(0xFFCD1622),
    yellow: Color(0xFF906106),
    green: Color(0xFF017B37),
    teal: Color(0xFF04786E),
    blue: Color(0xFF0069CD),
    purple: Color(0xFF864AD2),
    pink: Color(0xFFBC3181),
    onOrange: Color(0xFFFFFFFF),
    line: Color(0x380A0A0A),
    markSquare: Color(0xFFF38230),
  );

  /// Returns the palette instance for [brightness].
  static AppBrandColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// The mode this palette is tuned for.
  final Brightness brightness;

  /// Oxide orange, the brand color (`--primary`).
  final Color oxide;

  /// Red — errors and destructive actions.
  final Color red;

  /// Yellow — warnings and work in progress.
  final Color yellow;

  /// Green — done, shipped, available, saved.
  final Color green;

  /// Teal — categories and charts.
  final Color teal;

  /// Blue — tips and information.
  final Color blue;

  /// Purple — categories and charts.
  final Color purple;

  /// Pink — categories and charts.
  final Color pink;

  /// Text color on solid oxide orange.
  final Color onOrange;

  /// Hairline color for ring art: the mode's foreground at 22% opacity.
  final Color line;

  /// The wordmark's trailing square; bright orange in both modes.
  final Color markSquare;

  /// Success status role (`--green`).
  Color get success => green;

  /// Warning status role (`--yellow`).
  Color get warning => yellow;

  /// Info status role (`--blue`).
  Color get info => blue;

  /// Destructive status role (`--red`).
  Color get destructive => red;

  /// Resolves a status role to its brand color.
  ///
  /// Returns null for [AppStatusRole.neutral] because neutral status is plain
  /// grey, which comes from the theme's secondary/muted tokens, not from the
  /// brand palette.
  Color? roleColor(AppStatusRole role) => switch (role) {
    AppStatusRole.success => success,
    AppStatusRole.warning => warning,
    AppStatusRole.info => info,
    AppStatusRole.destructive => destructive,
    AppStatusRole.neutral => null,
  };

  @override
  AppBrandColors copyWith({
    Brightness? brightness,
    Color? oxide,
    Color? red,
    Color? yellow,
    Color? green,
    Color? teal,
    Color? blue,
    Color? purple,
    Color? pink,
    Color? onOrange,
    Color? line,
    Color? markSquare,
  }) {
    return AppBrandColors(
      brightness: brightness ?? this.brightness,
      oxide: oxide ?? this.oxide,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      teal: teal ?? this.teal,
      blue: blue ?? this.blue,
      purple: purple ?? this.purple,
      pink: pink ?? this.pink,
      onOrange: onOrange ?? this.onOrange,
      line: line ?? this.line,
      markSquare: markSquare ?? this.markSquare,
    );
  }

  @override
  AppBrandColors lerp(covariant AppBrandColors? other, double t) {
    if (other == null) {
      return this;
    }

    return AppBrandColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      oxide: Color.lerp(oxide, other.oxide, t)!,
      red: Color.lerp(red, other.red, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      green: Color.lerp(green, other.green, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      onOrange: Color.lerp(onOrange, other.onOrange, t)!,
      line: Color.lerp(line, other.line, t)!,
      markSquare: Color.lerp(markSquare, other.markSquare, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBrandColors &&
          runtimeType == other.runtimeType &&
          brightness == other.brightness &&
          oxide == other.oxide &&
          red == other.red &&
          yellow == other.yellow &&
          green == other.green &&
          teal == other.teal &&
          blue == other.blue &&
          purple == other.purple &&
          pink == other.pink &&
          onOrange == other.onOrange &&
          line == other.line &&
          markSquare == other.markSquare;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    brightness,
    oxide,
    red,
    yellow,
    green,
    teal,
    blue,
    purple,
    pink,
    onOrange,
    line,
    markSquare,
  );
}

/// Provides access to [AppBrandColors] from the theme.
///
/// ```dart
/// final brand = context.theme.brand;
/// ```
extension AppBrandColorsTheme on FThemeData {
  /// The brand palette attached to this theme.
  ///
  /// Falls back to the palette for the theme's brightness when no
  /// [AppBrandColors] extension was attached (for example, a bare
  /// `FThemeData` built outside the app factory).
  AppBrandColors get brand {
    try {
      return extension<AppBrandColors>();
    } on Object {
      return AppBrandColors.forBrightness(colors.brightness);
    }
  }
}
