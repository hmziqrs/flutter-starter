import 'package:flutter/widgets.dart';

/// Stat cards in a grid (APP-BLOCKS.md "StatGrid"): each child is its own
/// outline card; the grid brings only the gaps.
///
/// Two columns on narrow widths, the chosen column count (2–4) from 640dp.
class AppStatGrid extends StatelessWidget {
  const AppStatGrid({required this.children, this.columns = 4, super.key});

  /// The cards, usually `AppStatCard`s.
  final List<Widget> children;

  /// Columns from the wide layout, capped at 4.
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final columnCount = wide ? columns.clamp(1, 4) : 2;
        final rowCount = (children.length / columnCount).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var row = 0; row < rowCount; row++) ...<Widget>[
              if (row > 0) const SizedBox(height: 12),
              // The row's stretch needs a bounded height, which a Column
              // never gives its children; IntrinsicHeight derives it from
              // the cards' content.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                      if (cell > 0) const SizedBox(width: 12),
                      Expanded(
                        child: row * columnCount + cell < children.length
                            ? children[row * columnCount + cell]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
