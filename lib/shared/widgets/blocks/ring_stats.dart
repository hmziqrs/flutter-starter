import 'package:flutter/widgets.dart';
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';

/// One entry of an [AppRingStats] grid: a real number and its label, with
/// either a share of a ring (0–1) or a count of segments.
typedef AppRingStat = ({String value, String label, double? share, int? count});

/// Key numbers as ring gauges (BRAND.md s7): a grid of [AppRingGauge]s,
/// one accent ring each — only the line plus one orange accent.
///
/// Only real numbers belong here. The brand block is `grid gap-8
/// sm:grid-cols-3`: one column below 640, up to [columns] from 640.
class AppRingStats extends StatelessWidget {
  const AppRingStats({required this.stats, this.columns = 3, super.key});

  final List<AppRingStat> stats;

  /// Columns from the wide layout, capped at 3.
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final columnCount = wide ? columns.clamp(1, 3) : 1;
        final rowCount = (stats.length / columnCount).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var row = 0; row < rowCount; row++) ...<Widget>[
              if (row > 0) const SizedBox(height: 32),
              Row(
                children: <Widget>[
                  for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                    if (cell > 0) const SizedBox(width: 32),
                    Expanded(
                      child: row * columnCount + cell < stats.length
                          ? AppRingGauge(
                              value: stats[row * columnCount + cell].value,
                              label: stats[row * columnCount + cell].label,
                              share: stats[row * columnCount + cell].share,
                              count: stats[row * columnCount + cell].count,
                              // The block's `flex items-center gap-4.5`.
                              spacing: 18,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
