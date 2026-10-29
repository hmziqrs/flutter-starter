import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// How an [AppDataTable] draws its lines (BRAND.md s8 "Tables").
enum AppDataTableStyle {
  /// Boxed: a rounded outline, the accent column on a soft primary wash.
  boxed,

  /// Docs: a strong line under the headings, thin lines between rows.
  docs,
}

/// The brand data table (BRAND.md s8): boxed and rounded on landing and
/// product pages, with the column that matters on a soft primary wash
/// (about 7%) and its heading in primary; or the docs lines style with a
/// strong line under the headings and thin lines between rows.
///
/// Names in the first column stay in the text color; the other body cells
/// read muted so the accent column stands out. Cell text comes from the
/// caller as plain strings.
class AppDataTable extends StatelessWidget {
  const AppDataTable({
    required this.columns,
    required this.rows,
    this.accentColumn,
    this.style = AppDataTableStyle.boxed,
    super.key,
  });

  /// Heading labels, one per column.
  final List<String> columns;

  /// Body rows; each row must hold one cell per column.
  final List<List<String>> rows;

  /// The index of the accent column — the one that matters, e.g. the
  /// recommended plan. Null draws no wash.
  final int? accentColumn;

  final AppDataTableStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final boxed = style == AppDataTableStyle.boxed;
    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: boxed
          ? null
          : TableBorder(
              horizontalInside: BorderSide(color: theme.colors.border),
            ),
      children: <TableRow>[
        TableRow(
          decoration: BoxDecoration(
            border: boxed
                ? Border(bottom: BorderSide(color: theme.colors.border))
                : Border(bottom: BorderSide(color: theme.colors.foreground)),
          ),
          children: <Widget>[
            for (var index = 0; index < columns.length; index++)
              _cell(
                context,
                text: columns[index],
                accent: index == accentColumn,
                heading: true,
                firstColumn: index == 0,
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: <Widget>[
              for (var index = 0; index < row.length; index++)
                _cell(
                  context,
                  text: row[index],
                  accent: index == accentColumn,
                  heading: false,
                  firstColumn: index == 0,
                ),
            ],
          ),
      ],
    );
    if (!boxed) {
      return table;
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: table,
    );
  }

  Widget _cell(
    BuildContext context, {
    required String text,
    required bool accent,
    required bool heading,
    required bool firstColumn,
  }) {
    final theme = context.theme;
    final boxed = style == AppDataTableStyle.boxed;
    // Names in the first column and the accent column stay in the text
    // color; the remaining body cells read muted.
    final emphasized = heading || accent || firstColumn;
    final color = emphasized ? theme.colors.foreground : theme.colors.mutedForeground;
    if (heading) {
      return TableCell(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: accent && boxed ? theme.colors.primary.withValues(alpha: 0.07) : null,
          child: Text(
            text,
            style: theme.typography.body.sm.copyWith(
              color: accent
                  ? theme.colors.primary
                  : boxed
                  ? theme.colors.mutedForeground
                  : theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: accent && boxed ? theme.colors.primary.withValues(alpha: 0.07) : null,
        child: Text(
          text,
          style: theme.typography.body.sm.copyWith(
            color: color,
            fontWeight: heading || accent ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
