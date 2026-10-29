import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A ring gauge filled with a brand material (the kits' `material-gauge`):
/// the border-colored track carries a material arc clipped to the drawn
/// sweep, starting at the top with round caps — and a whole number above 1
/// splits the ring into that many butt-cap segments with 6-unit gaps, over
/// no track, the way the kit's dash math draws a count.
///
/// The recipe is the gauge's own: radius 29 of the 72 box, stroke 8 — the
/// arc ends in round caps like the kit's `stroke-linecap="round"`. Pure
/// graphic — pair it with a value and its label in the page, the way
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

  /// The drawn share of the ring, 0 to 1; a whole number above 1 splits the
  /// ring into that many segments (the kit's count mode).
  final double value;

  /// Outer edge length of the square the gauge paints in.
  final double size;

  /// Ring thickness.
  final double thickness;

  bool get _isCount => value > 1;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _GaugeTrackPainter(
          trackColor: theme.colors.border,
          thickness: thickness,
          drawTrack: !_isCount,
        ),
        child: ClipPath(
          clipper: _GaugeSectorClipper(
            value: value,
            thickness: thickness,
          ),
          // The kit's data-material-sheet: floor under the metal.
          child: BrandMaterialSheet(recipe: recipe),
        ),
      ),
    );
  }
}

/// Draws the full border-colored ring the material arc sits on; a count
/// splits the ring instead, so it draws no track (the kit draws the track
/// circle only when the value is at most 1).
class _GaugeTrackPainter extends CustomPainter {
  const _GaugeTrackPainter({
    required this.trackColor,
    required this.thickness,
    required this.drawTrack,
  });

  final Color trackColor;

  final double thickness;

  final bool drawTrack;

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawTrack) {
      return;
    }
    canvas.drawCircle(
      size.center(Offset.zero),
      _GaugeSectorClipper.centerlineRadius(size.shortestSide, thickness),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = trackColor,
    );
  }

  @override
  bool shouldRepaint(_GaugeTrackPainter oldDelegate) =>
      trackColor != oldDelegate.trackColor ||
      thickness != oldDelegate.thickness ||
      drawTrack != oldDelegate.drawTrack;
}

/// Clips the material quad to the gauge's sweep, starting at 12 o'clock and
/// running clockwise: a share (0 to 1) sweeps that far with round end caps;
/// a count above 1 draws that many segments, each short of its slice by the
/// kit's 6-unit gap, with flat (butt) ends.
class _GaugeSectorClipper extends CustomClipper<Path> {
  const _GaugeSectorClipper({required this.value, required this.thickness});

  /// The stroke's centerline radius: the kit draws radius 29 with a 3px
  /// margin in the 72 box, so the ring's outer edge sits 3 scaled px in.
  static double centerlineRadius(double side, double thickness) =>
      (side - 2 * side * (3 / 72) - thickness) / 2;

  final double value;

  final double thickness;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final radius = centerlineRadius(size.shortestSide, thickness);
    final path = Path();
    const startAngle = -math.pi / 2;
    if (value <= 0) {
      return path;
    }
    // The full ring needs no sector path at all.
    if (value == 1) {
      return path
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: center, radius: radius))
        ..addOval(Rect.fromCircle(center: center, radius: radius - thickness));
    }
    final isCount = value > 1;
    // The kit's count dash: `(c / value - 6) 6` in the 72 box, so the gap is
    // 6 box units along the circumference.
    final slice = 2 * math.pi / value;
    final gapAngle = isCount ? (6 * size.shortestSide / 72) / radius : 0.0;
    final sweep = isCount ? slice - gapAngle : slice * value;
    for (var index = 0; index < (isCount ? value.ceil() : 1); index++) {
      final from = startAngle + slice * index + (isCount ? gapAngle / 2 : 0.0);
      _annularSector(path, center, radius, thickness, from, sweep);
      // A share ends in round caps (the kit's `stroke-linecap="round"`); a
      // count's segments end flat.
      if (!isCount) {
        final capRadius = thickness / 2;
        for (final angle in <double>[from, from + sweep]) {
          path.addOval(
            Rect.fromCircle(
              center: Offset(
                center.dx + (radius - capRadius) * math.cos(angle),
                center.dy + (radius - capRadius) * math.sin(angle),
              ),
              radius: capRadius,
            ),
          );
        }
      }
    }
    return path;
  }

  void _annularSector(
    Path path,
    Offset center,
    double radius,
    double thickness,
    double from,
    double sweep,
  ) {
    path
      ..moveTo(center.dx + radius * math.cos(from), center.dy + radius * math.sin(from))
      ..arcTo(Rect.fromCircle(center: center, radius: radius), from, sweep, false)
      ..lineTo(
        center.dx + (radius - thickness) * math.cos(from + sweep),
        center.dy + (radius - thickness) * math.sin(from + sweep),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius - thickness),
        from + sweep,
        -sweep,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_GaugeSectorClipper oldDelegate) =>
      oldDelegate.value != value || oldDelegate.thickness != thickness;
}
