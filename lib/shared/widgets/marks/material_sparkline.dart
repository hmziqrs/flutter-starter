import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A sparkline with a brand-material area fill (the shader-kit variant): the
/// material shows through the area under the curve, and the curve itself
/// strokes in the foreground so the trend reads even where the material runs
/// quiet.
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
            ClipPath(
              clipper: _AreaClipper(points: points),
              child: BrandMaterialSurface(recipe: recipe),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CurvePainter(points: points, color: theme.colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The curve geometry for a normalized series: x steps evenly across the
/// width, y maps 0 to the bottom and 1 to the top, both inset by the stroke
/// so the line never clips.
class _SparklineGeometry {
  _SparklineGeometry(this.points, this.size) {
    const inset = 3.0;
    final width = size.width - inset * 2;
    final height = size.height - inset * 2;
    final count = points.length;
    if (count < 2) {
      return;
    }
    final step = width / (count - 1);
    _vertices = <Offset>[
      for (var index = 0; index < count; index++)
        Offset(
          inset + step * index,
          size.height - inset - points[index].clamp(0.0, 1.0) * height,
        ),
    ];
  }

  final List<double> points;

  final Size size;

  List<Offset> _vertices = const <Offset>[];

  bool get drawable => _vertices.length >= 2;

  /// The polyline itself.
  Path get curvePath => Path()..addPolygon(_vertices, false);

  /// The area under the polyline, closed along the bottom edge.
  Path get areaPath {
    if (!drawable) {
      return Path();
    }
    return Path()..addPolygon(
      <Offset>[
        ..._vertices,
        Offset(_vertices.last.dx, size.height),
        Offset(_vertices.first.dx, size.height),
      ],
      true,
    );
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

/// Strokes the curve over the material area.
class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.points, required this.color});

  final List<double> points;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _SparklineGeometry(points, size);
    if (!geometry.drawable) {
      return;
    }
    canvas.drawPath(
      geometry.curvePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter oldDelegate) =>
      !listEquals(oldDelegate.points, points) || color != oldDelegate.color;
}
