import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// One row of an [AppBeforeAfter]: what the row is about, the old way, and
/// what the product does instead.
class AppBeforeAfterRow {
  const AppBeforeAfterRow({
    required this.what,
    required this.before,
    required this.after,
  });

  /// What the row compares, e.g. "Colors" — the quiet lead-in on its own
  /// column from the wide layout (before-after.svelte's 16rem column).
  final String what;

  /// The manual way, struck through.
  final String before;

  /// What replaces it, marked with the filled primary ring.
  final String after;
}

/// Before and after (BRAND.md s8, before-after.svelte): a hairline list
/// where the manual way is struck through and the marked side carries the
/// tool's way.
///
/// The block is one list with a hairline on top, one row per comparison,
/// each closed by a hairline underneath (the svelte `ul.border-t` with
/// `li.border-b py-4`). Every row reads the struck "before" in muted words
/// (decoration-muted-foreground/70), then the "after" behind a filled
/// primary ring marker — only colors and the strike change, nothing moves.
/// From 1024dp the row opens into the svelte's four-column grid: the
/// 16rem "what" column, the struck side, the arrow, the marked side.
class AppBeforeAfter extends StatelessWidget {
  const AppBeforeAfter({
    required this.rows,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    super.key,
  });

  final List<AppBeforeAfterRow> rows;

  /// For screen readers, e.g. "By hand" — prefixes every struck item.
  final String beforeLabel;

  /// For screen readers, e.g. "With the kit" — prefixes every marked item.
  final String afterLabel;

  /// The svelte row opens into its four-column grid at `lg`.
  static const double wideBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        return Container(
          // The list's opening hairline (before-after.svelte: ul.border-t);
          // every row carries its own closing one.
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final row in rows)
                _Row(row: row, wide: wide, beforeLabel: beforeLabel, afterLabel: afterLabel),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.wide,
    required this.beforeLabel,
    required this.afterLabel,
  });

  final AppBeforeAfterRow row;

  final bool wide;

  final String beforeLabel;

  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // The row's air and closing hairline (li.border-b py-4); the base size
    // is the svelte's 0.9rem on a relaxed leading, the "what" lead-in the
    // 0.8125rem muted caption.
    final body = TextStyle(
      fontSize: 14.4,
      height: 1.625,
      color: theme.colors.foreground,
    );
    final beforeStyle = body.copyWith(
      color: theme.colors.mutedForeground,
      decoration: TextDecoration.lineThrough,
      decorationColor: theme.colors.mutedForeground.withValues(alpha: 0.70),
    );
    final after = Semantics(
      label: '$afterLabel: ${row.after}',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          // The filled primary ring (Marker filled text-primary), centered
          // on the line it marks (span.inline-flex items-center gap-2).
          AppRingMarker(filled: true, color: theme.colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(row.after, style: body)),
        ],
      ),
    );
    final before = Semantics(
      label: '$beforeLabel: ${row.before}',
      excludeSemantics: true,
      child: Text(row.before, style: beforeStyle),
    );
    final what = Text(
      row.what,
      style: body.copyWith(fontSize: 13, color: theme.colors.mutedForeground),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colors.border)),
      ),
      // The stacked row runs what, struck, marked; the wide row opens the
      // svelte grid (16rem | 1fr | 1.25rem | 1fr, gap-x-4) and shows the
      // arrow between the sides.
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 256, child: what),
                const SizedBox(width: 16),
                Expanded(child: before),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4),
                  child: Icon(
                    FLucideIcons.arrowRight,
                    size: 15,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: after),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                what,
                const SizedBox(height: 4),
                before,
                const SizedBox(height: 4),
                after,
              ],
            ),
    );
  }
}
