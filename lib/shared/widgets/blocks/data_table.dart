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
/// The table hugs its columns the way the svelte auto-layout does: the
/// names column fits its content, the rest keep a 144dp floor
/// (min-w-36). Names in the first column stay in the text color on one
/// line; the other body cells read muted so the accent column stands out.
/// Cell text comes from the caller as plain strings.
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
      // The svelte auto-layout: the names column fits its (nowrap) content,
      // every other column keeps min-w-36 (144dp) at its floor.
      columnWidths: <int, TableColumnWidth>{
        for (var index = 0; index < columns.length; index++)
          index: index == 0
              ? const IntrinsicColumnWidth()
              : const MaxColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(144)),
      },
      // Body rows carry a thin line only between rows; the card's outline
      // (or nothing, in the docs style) closes the last one.
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
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
          TableRow(
            decoration: boxed && rowIndex < rows.length - 1
                ? BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.colors.border)),
                  )
                : null,
            children: <Widget>[
              for (var index = 0; index < rows[rowIndex].length; index++)
                _cell(
                  context,
                  text: rows[rowIndex][index],
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
    // Headings always read in the text color (data-table.svelte:
    // `font-medium text-foreground`), the washed one in primary; body names
    // stay in the text color and the remaining cells read muted. The accent
    // column is a wash, never a recolor.
    final color = heading || (!accent && firstColumn)
        ? theme.colors.foreground
        : theme.colors.mutedForeground;
    if (heading) {
      return TableCell(
        child: Container(
          padding: EdgeInsetsDirectional.only(
            // Boxed cells breathe at 16 (px-4); the docs lines style sits
            // tighter at 12 (px-3).
            start: boxed ? 16 : 12,
            end: boxed ? 16 : 12,
            top: 10,
            bottom: 10,
          ),
          color: accent && boxed ? theme.colors.primary.withValues(alpha: 0.07) : null,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.sm.copyWith(
              color: accent ? theme.colors.primary : color,
              fontWeight: FontWeight.w500,
              // The heading's line runs at normal leading, so the 40dp bar
              // is 10 + text + 10 (data-table.svelte: h-auto py-2.5).
              height: 1.5,
            ),
          ),
        ),
      );
    }
    return TableCell(
      child: Container(
        // Body cells: 12dp of air above and below (py-3); headings keep
        // py-2.5. The cell's line runs at relaxed leading, giving the
        // reference's 47dp rows (leading-relaxed).
        padding: EdgeInsetsDirectional.only(
          start: boxed ? 16 : 12,
          end: boxed ? 16 : 12,
          top: 12,
          bottom: 12,
        ),
        color: accent && boxed ? theme.colors.primary.withValues(alpha: 0.07) : null,
        child: Text(
          text,
          style: theme.typography.body.sm.copyWith(color: color, height: 1.625),
        ),
      ),
    );
  }
}
