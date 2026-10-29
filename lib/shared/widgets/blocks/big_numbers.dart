import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// One number of an [AppBigNumbers] row.
typedef AppBigNumber = ({String value, String label});

/// Big numbers under a strong line (BRAND.md s8, About and Changelog): a
/// row of huge w500 numbers, each under a 1px foreground line, with its
/// label in muted words.
///
/// Numbers use proportional digits and stay at w500 — nothing heavier. The
/// size follows the svelte block: 48 (text-[3rem]) growing to 84
/// (md:text-[5.25rem]) from 640dp, tracking −0.05em on a 0.95 leading.
/// Only real numbers belong here.
class AppBigNumbers extends StatelessWidget {
  const AppBigNumbers({required this.numbers, this.columns = 3, this.fontSize = 48, super.key});

  final List<AppBigNumber> numbers;

  /// Columns from the wide layout, capped at 4.
  final int columns;

  /// The number size at the base scale; the wide layout grows it by the
  /// svelte's md step (1.75×, 48 → 84).
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final columnCount = wide ? columns.clamp(1, 4) : 2;
        final scaled = wide ? fontSize * 1.75 : fontSize;
        final rowCount = (numbers.length / columnCount).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var row = 0; row < rowCount; row++) ...<Widget>[
              if (row > 0) const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                    if (cell > 0) const SizedBox(width: 32),
                    Expanded(
                      child: row * columnCount + cell < numbers.length
                          ? _Number(
                              number: numbers[row * columnCount + cell],
                              fontSize: scaled,
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

class _Number extends StatelessWidget {
  const _Number({required this.number, required this.fontSize});

  final AppBigNumber number;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(height: 1, color: theme.colors.foreground),
        // The line hangs 16dp above the number (pt-4) and the label sits one
        // 8dp gap under it (gap-2).
        const SizedBox(height: 16),
        Text(
          number.value,
          style: TextStyle(
            fontSize: fontSize,
            height: 0.95,
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.05 * fontSize,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          number.label,
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}
