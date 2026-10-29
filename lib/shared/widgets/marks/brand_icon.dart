import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:starter/shared/widgets/marks/simple_icons.dart';

/// Parses (once, then memoizes) the SVG path of a bundled Simple Icons glyph
/// into a Dart [Path]. The data is a committed constant, so the cache is
/// keyed by slug and lives for the app's lifetime.
Path brandIconPath(String name) => _parsedPaths.putIfAbsent(
  name,
  () => parseSvgPathData(simpleIconPaths[name] ?? ''),
);

final Map<String, Path> _parsedPaths = <String, Path>{};

/// A third-party logo drawn from the bundled Simple Icons set
/// (`simple_icons.dart`, CC0): GitHub, X and friends as monochrome glyphs,
/// tinted by the icon color like any other icon.
///
/// The kit never recolors or distorts a logo: one color, square, padding
/// comes from the caller. Pass [semanticLabel] when the icon stands alone;
/// decorations already announcing the brand can leave it null.
class BrandIcon extends StatelessWidget {
  const BrandIcon({required this.name, this.size = 24, this.color, this.semanticLabel, super.key});

  /// The Simple Icons slug, e.g. `github` or `x` (the keys of
  /// [simpleIconPaths]).
  final String name;

  /// Edge length of the square the glyph paints in.
  final double size;

  /// The glyph color; from the ambient [IconTheme] when null, like [Icon].
  final Color? color;

  /// What screen readers call the icon, e.g. "GitHub". Defaults to the
  /// icon's human name from [simpleIconNames].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(simpleIconPaths.containsKey(name), 'BrandIcon: "$name" is not in the bundled set.');
    final label = semanticLabel ?? simpleIconNames[name] ?? name;
    final glyphColor =
        color ??
        IconTheme.of(context).color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF000000);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _BrandIconPainter(path: brandIconPath(name), color: glyphColor),
        ),
      ),
    );
  }
}

class _BrandIconPainter extends CustomPainter {
  const _BrandIconPainter({required this.path, required this.color});

  final Path path;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    // Simple Icons glyphs live in a 24x24 viewBox.
    canvas
      ..save()
      ..scale(size.width / 24, size.height / 24)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_BrandIconPainter oldDelegate) =>
      !identical(path, oldDelegate.path) || color != oldDelegate.color;
}
