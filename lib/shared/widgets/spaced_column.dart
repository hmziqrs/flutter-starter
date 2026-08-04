import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A [Column] that intersperses a fixed [gap] between each child.
///
/// Equivalent to a [Column] whose children are separated by
/// `SizedBox(height: gap)`. The for-index spread pattern is preserved so
/// callers can still hand in a `for` builder via [children] — including
/// conditional entries that omit a trailing separator.
class SpacedColumn extends StatelessWidget {
  const SpacedColumn({
    required this.children,
    this.gap = AppSpacing.sm,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    super.key,
  });

  /// Vertical space inserted between successive children. Defaults to
  /// [AppSpacing.sm] to match the historical settings tile spacing.
  final double gap;

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ],
    );
  }
}
