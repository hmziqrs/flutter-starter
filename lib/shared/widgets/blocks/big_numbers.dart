import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// One number of an [AppBigNumbers] row.
typedef AppBigNumber = ({String value, String label});

/// Big numbers under a strong line (BRAND.md s8, About and Changelog): a
/// row of huge w500 numbers, each under a 1px foreground line, with its
/// label in muted words.
///
/// Numbers use proportional digits and stay at w500 — nothing heavier.
/// Only real numbers belong here.
class AppBigNumbers extends StatelessWidget {
  const AppBigNumbers({required this.numbers, this.columns = 3, this.fontSize = 28, super.key});

  final List<AppBigNumber> numbers;

  /// Columns from the wide layout, capped at 4.
  final int columns;

  /// The number size; 28 keeps app screens quiet.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final columnCount = wide ? columns.clamp(1, 4) : 2;
        final rowCount = (numbers.length / columnCount).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var row = 0; row < rowCount; row++) ...<Widget>[
              if (row > 0) const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                    if (cell > 0) const SizedBox(width: 24),
                    Expanded(
                      child: row * columnCount + cell < numbers.length
                          ? _Number(
                              number: numbers[row * columnCount + cell],
                              fontSize: fontSize,
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
        const SizedBox(height: 12),
        Text(
          number.value,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.1,
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * fontSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          number.label,
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}
