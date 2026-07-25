import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Bounded responsive units derived from the logical space available to the app.
///
/// Layout and typography scaling intentionally use logical width rather than
/// [MediaQueryData.devicePixelRatio]. Density is only exposed through [pixel]
/// and [snap] for drawing physical-pixel-aligned details.
@immutable
final class AppUnit {
  const AppUnit._({
    required this.size,
    required this.devicePixelRatio,
    required this.spacingScale,
    required this.typographyScale,
  });

  factory AppUnit.of(BuildContext context) {
    return AppUnit.fromMediaQuery(MediaQuery.of(context));
  }

  factory AppUnit.fromMediaQuery(MediaQueryData mediaQuery) {
    return AppUnit.fromSize(
      mediaQuery.size,
      devicePixelRatio: mediaQuery.devicePixelRatio,
    );
  }

  factory AppUnit.fromSize(
    Size size, {
    required double devicePixelRatio,
  }) {
    if (!size.width.isFinite || size.width < 0) {
      throw ArgumentError.value(size.width, 'size.width', 'Width must be finite and non-negative.');
    }
    if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
      throw ArgumentError.value(
        devicePixelRatio,
        'devicePixelRatio',
        'Device pixel ratio must be finite and greater than zero.',
      );
    }

    return AppUnit._(
      size: size,
      devicePixelRatio: devicePixelRatio,
      spacingScale: _scaleForWidth(
        size.width,
        minimum: minimumSpacingScale,
        maximum: maximumSpacingScale,
      ),
      typographyScale: _scaleForWidth(
        size.width,
        minimum: minimumTypographyScale,
        maximum: maximumTypographyScale,
      ),
    );
  }

  static const referenceWidth = 390.0;
  static const minimumWidth = 320.0;
  static const maximumWidth = 1200.0;
  static const minimumSpacingScale = 0.9;
  static const maximumSpacingScale = 1.2;
  static const minimumTypographyScale = 0.9;
  static const maximumTypographyScale = 1.15;
  static const baseSpace = 4.0;

  final Size size;
  final double devicePixelRatio;
  final double spacingScale;
  final double typographyScale;

  /// One physical display pixel expressed in Flutter logical pixels.
  double get pixel => 1 / devicePixelRatio;

  /// Scales a layout or spacing value using the bounded responsive scale.
  double un(num value) => value * spacingScale;

  /// Returns a multiple of the app's four-point spacing unit.
  double sp([num multiplier = 1]) => un(baseSpace * multiplier);

  /// Scales a design font size before the ambient [TextScaler] is applied.
  double font(num value) => value * typographyScale;

  /// Aligns a logical value to the nearest physical display pixel.
  double snap(num logicalPixels) {
    return (logicalPixels * devicePixelRatio).roundToDouble() / devicePixelRatio;
  }

  static double _scaleForWidth(
    double width, {
    required double minimum,
    required double maximum,
  }) {
    if (width <= referenceWidth) {
      final progress = ((width - minimumWidth) / (referenceWidth - minimumWidth)).clamp(
        0.0,
        1.0,
      );
      return lerpDouble(minimum, 1, progress)!;
    }

    final progress = ((width - referenceWidth) / (maximumWidth - referenceWidth)).clamp(
      0.0,
      1.0,
    );
    return lerpDouble(1, maximum, progress)!;
  }
}

extension AppUnitBuildContext on BuildContext {
  AppUnit get appUnit => AppUnit.of(this);
}
