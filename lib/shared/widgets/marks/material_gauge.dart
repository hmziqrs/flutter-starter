import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A ring gauge filled with a brand material (the shader-kit variant of the
/// ring gauge): the muted track carries a material arc clipped to the drawn
/// sweep.
///
/// Pure graphic — pair it with a value and its label in the page, the way
/// `AppRingGauge` does.
class MaterialGauge extends StatelessWidget {
  const MaterialGauge({
    required this.recipe,
    required this.value,
    this.size = 72,
    this.thickness = 8,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The drawn share of the ring, 0 to 1; clamped into range.
  final double value;

  /// Outer edge length of the square the gauge paints in.
  final double size;

  /// Ring thickness.
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GaugeTrackPainter(trackColor: theme.colors.muted, thickness: thickness),
        child: ClipPath(
          clipper: _GaugeSectorClipper(
            value: value.clamp(0.0, 1.0),
            thickness: thickness,
          ),
          child: BrandMaterialSurface(recipe: recipe),
        ),
      ),
    );
  }
}

/// Draws the full muted ring the material arc sits on.
class _GaugeTrackPainter extends CustomPainter {
  const _GaugeTrackPainter({required this.trackColor, required this.thickness});

  final Color trackColor;

  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      (size.shortestSide - thickness) / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = trackColor,
    );
  }

  @override
  bool shouldRepaint(_GaugeTrackPainter oldDelegate) =>
      trackColor != oldDelegate.trackColor || thickness != oldDelegate.thickness;
}

/// Clips the material quad to the gauge's swept annular sector, starting at
/// 12 o'clock and running clockwise.
class _GaugeSectorClipper extends CustomClipper<Path> {
  const _GaugeSectorClipper({required this.value, required this.thickness});

  final double value;

  final double thickness;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = (size.shortestSide - thickness) / 2;
    final innerRadius = outerRadius - thickness;
    final path = Path();
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * value;
    if (value >= 1) {
      path
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: center, radius: outerRadius))
        ..addOval(Rect.fromCircle(center: center, radius: innerRadius));
      return path;
    }
    path
      ..moveTo(
        center.dx + outerRadius * math.cos(startAngle),
        center.dy + outerRadius * math.sin(startAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweep,
        false,
      )
      ..lineTo(
        center.dx + innerRadius * math.cos(startAngle + sweep),
        center.dy + innerRadius * math.sin(startAngle + sweep),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweep,
        -sweep,
        false,
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_GaugeSectorClipper oldClipper) =>
      oldClipper.value != value || oldClipper.thickness != thickness;
}
