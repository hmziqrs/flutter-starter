import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A hairline with a ring at the end (BRAND.md s7): the line in the brand's
/// ring-art hairline color, the ring in the accent.
///
/// Rings are only the line plus one orange accent, so the marker stays
/// hollow unless [RingDivider.filled] marks something on, open, done or
/// selected. Decorative: pair it with a heading or a label that carries the
/// meaning.
class RingDivider extends StatelessWidget {
  const RingDivider({this.filled = false, this.accentColor, this.gap = 10, super.key});

  /// Fills the end ring: on, open, done or selected.
  final bool filled;

  /// The end ring's color; defaults to the theme's primary.
  final Color? accentColor;

  /// Space between the hairline and the ring.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 1,
            color: theme.brand.line,
          ),
        ),
        SizedBox(width: gap),
        AppRingMarker(
          filled: filled,
          color: accentColor ?? theme.colors.primary,
        ),
      ],
    );
  }
}
