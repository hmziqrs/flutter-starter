import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The brand's hollow ring marker (BRAND.md s7): a small ring at 1.75px
/// border that takes the surrounding text color.
///
/// [filled] means on, open, done or selected and paints the disc in the same
/// color; hollow means everything else. Never a solid dot at rest, never a
/// square, never an emoji. Decorative on its own: pair it with a text label
/// that carries the meaning.
class AppRingMarker extends StatelessWidget {
  const AppRingMarker({
    this.filled = false,
    this.color,
    this.size = 9,
    this.borderWidth = 1.75,
    super.key,
  });

  final bool filled;

  final Color? color;

  final double size;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? DefaultTextStyle.of(context).style.color ?? context.theme.colors.foreground;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: filled ? resolvedColor : Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: resolvedColor, width: borderWidth),
        ),
      ),
    );
  }
}
