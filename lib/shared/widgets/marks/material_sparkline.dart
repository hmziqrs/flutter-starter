import 'dart:ui' as ui show Gradient;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A sparkline with a brand-material area fill (the kits' `material-sparkline`):
/// the material shows through the area under the curve, fading toward the
/// bottom (the kit's mask gradient), the curve strokes in the foreground so
/// the trend reads even where the material runs quiet, and the latest point
/// carries a primary dot.
class MaterialSparkline extends StatelessWidget {
  const MaterialSparkline({
    required this.recipe,
    required this.points,
    this.extent = 64,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The series, left to right, already normalized to 0..1. Fewer than two
  /// points draws the material quad with no curve.
  final List<double> points;

  /// Height of the quad; it stretches to the given width.
  final double extent;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ClipRRect(
      borderRadius: theme.style.borderRadius.md.resolve(Directionality.of(context)),
      child: SizedBox(
        height: extent,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The kit's area mask: the material area fades to 5% at the
            // bottom edge, so the fill settles instead of stopping.
            ShaderMask(
              shaderCallback: (bounds) => ui.Gradient.linear(
                Offset.zero,
                Offset(0, bounds.height),
                // Alpha carriers for the dstIn mask: full at the top, the
                // kit's 5% at the bottom.
                const <Color>[Color(0xFFFFFFFF), Color(0x0DFFFFFF)],
              ),
              blendMode: BlendMode.dstIn,
              child: ClipPath(
                clipper: _AreaClipper(points: points),
                // The kit's data-material-sheet: floor under the metal, so
                // the fill's patches read on either page color.
                child: BrandMaterialSheet(recipe: recipe),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvePainter(
                  points: points,
                  color: theme.colors.foreground,
                  accentColor: theme.colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The curve geometry for a normalized series, ported from the kit's
/// `material-sparkline` (300x100 viewBox, pad 6): x steps evenly across the
/// full width, y maps 0 to `pad` above the bottom and 1 to `pad` below the
/// top, and the line runs through the points as cubic beziers whose control
/// points take a sixth of each neighbor delta (the kit's smoothing), with the
/// control y clamped into the box the way the kit's `y(v)` clamp does.
class _SparklineGeometry {
  _SparklineGeometry(this.points, this.size) {
    // The kit's pad: 6 of the 100-tall viewBox.
    final pad = size.height * 6 / 100;
    final count = points.length;
    if (count < 2) {
      return;
    }
    final step = size.width / (count - 1);
    double x(int index) => step * index;
    double y(int index) =>
        size.height - pad - points[index].clamp(0.0, 1.0) * (size.height - pad * 2);
    double clampY(double value) => value.clamp(0.0, size.height);
    Offset at(int index) => Offset(x(index.clamp(0, count - 1)), y(index.clamp(0, count - 1)));
    _vertices = <Offset>[for (var index = 0; index < count; index++) at(index)];
    final path = Path()..moveTo(_vertices.first.dx, _vertices.first.dy);
    for (var index = 1; index < count; index++) {
      final previous = at(index - 1);
      final twoBack = at(index - 2);
      final next = at(index + 1);
      path.cubicTo(
        previous.dx + (x(index) - twoBack.dx) / 6,
        clampY(previous.dy + (y(index) - twoBack.dy) / 6),
        x(index) - (next.dx - previous.dx) / 6,
        clampY(y(index) - (next.dy - previous.dy) / 6),
        x(index),
        y(index),
      );
    }
    _curvePath = path;
  }

  final List<double> points;

  final Size size;

  List<Offset> _vertices = const <Offset>[];

  Path _curvePath = Path();

  /// The sampled points, left to right; empty until the geometry is built.
  List<Offset> get vertices => _vertices;

  bool get drawable => _vertices.length >= 2;

  /// The smoothed line through the points.
  Path get curvePath => _curvePath;

  /// The area under the line, closed along the bottom edge.
  Path get areaPath {
    if (!drawable) {
      return Path();
    }
    return Path()
      ..addPath(
        _curvePath,
        Offset.zero,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }
}

/// Clips the material quad to the area under the curve.
class _AreaClipper extends CustomClipper<Path> {
  const _AreaClipper({required this.points});

  final List<double> points;

  @override
  Path getClip(Size size) => _SparklineGeometry(points, size).areaPath;

  @override
  bool shouldReclip(_AreaClipper oldClipper) => !listEquals(oldClipper.points, points);
}

/// Strokes the curve over the material area and marks the latest point.
class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.points, required this.color, required this.accentColor});

  final List<double> points;

  final Color color;

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _SparklineGeometry(points, size);
    if (!geometry.drawable) {
      return;
    }
    canvas
      ..drawPath(
        geometry.curvePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      )
      // The kit's `circle r=3.5 fill=var(--primary)` on the latest point.
      ..drawCircle(geometry.vertices.last, 3.5, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) =>
      !listEquals(oldDelegate.points, points) ||
      color != oldDelegate.color ||
      accentColor != oldDelegate.accentColor;
}
