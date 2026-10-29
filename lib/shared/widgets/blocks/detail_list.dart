import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// One fact of an [AppDetailList].
class AppDetailItem {
  const AppDetailItem({required this.label, this.value, this.mono = false, this.copyable = false});

  /// What the fact is called.
  final String label;

  /// The fact itself; null renders as the unset placeholder.
  final String? value;

  /// Machine values only — ids, keys, codes — run in JetBrains Mono.
  final bool mono;

  /// Shows a copy button beside the value.
  final bool copyable;
}

/// A record's facts (APP-BLOCKS.md "DetailList"): label and value pairs,
/// laid out as rows or as a grid.
///
/// Rows put the label on the left in a 160dp column and the value at the
/// row's end (`justify-between`), divided by 1px lines. The grid stacks
/// each label over its value in columns 32dp apart. No panel of its own —
/// the page draws the outline around it. Machine values run in mono; a
/// copyable value carries a copy button; a missing value shows [unsetText]
/// (or an em dash) in muted words. Copy button labels come from the caller
/// so pages can localize them.
class AppDetailList extends StatelessWidget {
  const AppDetailList({
    required this.items,
    this.layout = AppDetailListLayout.rows,
    this.columns = 2,
    this.unsetText,
    this.copyLabel,
    this.copiedLabel,
    super.key,
  });

  final List<AppDetailItem> items;

  final AppDetailListLayout layout;

  /// Grid columns from the wide layout; 2 or 3.
  final int columns;

  /// What a missing value reads, e.g. "Not set".
  final String? unsetText;

  /// The copy button's rest label; required when an item is copyable.
  final String? copyLabel;

  /// The copy button's copied label.
  final String? copiedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    assert(
      items.every((item) => !item.copyable) || copyLabel != null,
      'A copyable item needs copyLabel.',
    );
    if (layout == AppDetailListLayout.rows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // divide-y: one 1px line between rows, never doubled.
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0) Container(height: 1, color: theme.colors.border),
            _DetailRow(item: items[index], list: this),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 480;
        final columnCount = wide ? columns.clamp(1, 3) : 1;
        // The grid's gap-x-8 (32) between columns.
        const gap = 32.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index < items.length; index += columnCount)
              Padding(
                padding: EdgeInsets.only(bottom: index + columnCount < items.length ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                      if (cell > 0) const SizedBox(width: gap),
                      // The last row can be short: cells past the items
                      // stay empty rather than overflowing.
                      Expanded(
                        child: index + cell < items.length
                            ? _GridCell(item: items[index + cell], list: this)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

enum AppDetailListLayout { rows, grid }

/// The value, with the copy button 8dp beside it when there is one.
class _Value extends StatelessWidget {
  const _Value({required this.item, required this.list});

  final AppDetailItem item;

  final AppDetailList list;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final value = item.value ?? list.unsetText ?? '—';
    final isUnset = item.value == null;
    final valueWidget = Text(
      value,
      // min-w-0: long values wrap instead of pushing the row wide.
      style: theme.typography.body.sm.copyWith(
        color: isUnset ? theme.colors.mutedForeground : theme.colors.foreground,
        fontFamily: item.mono && !isUnset ? 'JetBrains Mono' : null,
      ),
    );
    if (!item.copyable || item.value == null) {
      return valueWidget;
    }
    // flex-wrap items-center gap-2 around the value and its button.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: <Widget>[
        valueWidget,
        AppCopyButton(
          text: item.value!,
          label: list.copyLabel!,
          copiedLabel: list.copiedLabel,
        ),
      ],
    );
  }
}

/// A rows-layout row: the label in a 160dp column, the value at the row's
/// end, 14dp of air above and below (py-3.5, justify-between).
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.item, required this.list});

  final AppDetailItem item;

  final AppDetailList list;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(
              item.label,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ),
          // sm:gap-6 keeps the pair apart while justify-between pushes the
          // value to the row's end.
          const SizedBox(width: 24),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _Value(item: item, list: list),
            ),
          ),
        ],
      ),
    );
  }
}

/// A grid cell: the label stacked over the value with 4dp between
/// (flex flex-col gap-1 py-3.5).
class _GridCell extends StatelessWidget {
  const _GridCell({required this.item, required this.list});

  final AppDetailItem item;

  final AppDetailList list;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.label,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
          const SizedBox(height: 4),
          _Value(item: item, list: list),
        ],
      ),
    );
  }
}
