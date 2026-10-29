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
/// No panel of its own — the page draws the outline around it. Machine
/// values run in mono; a copyable value carries a copy button; a missing
/// value shows [unsetText] (or an em dash) in muted words. Copy button
/// labels come from the caller so pages can localize them.
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
    final rows = <Widget>[
      for (final item in items) _DetailRow(item: item, list: this),
    ];
    if (layout == AppDetailListLayout.rows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < rows.length; index++) ...<Widget>[
            if (index > 0) Container(height: 1, color: theme.colors.border),
            rows[index],
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 480;
        final columnCount = wide ? columns.clamp(1, 3) : 1;
        const gap = 16.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index < rows.length; index += columnCount)
              Padding(
                padding: EdgeInsets.only(bottom: index + columnCount < rows.length ? 12 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var cell = 0; cell < columnCount; cell++) ...<Widget>[
                      if (cell > 0) const SizedBox(width: gap),
                      Expanded(child: rows[index + cell]),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.item, required this.list});

  final AppDetailItem item;

  final AppDetailList list;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final value = item.value ?? list.unsetText ?? '—';
    final isUnset = item.value == null;
    final valueStyle = theme.typography.body.sm.copyWith(
      color: isUnset ? theme.colors.mutedForeground : theme.colors.foreground,
      fontFamily: item.mono && !isUnset ? 'JetBrains Mono' : null,
    );
    final valueWidget = Text(value, style: valueStyle);
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
          const SizedBox(width: 16),
          Expanded(
            child: item.copyable && item.value != null
                ? Wrap(
                    spacing: 4,
                    children: <Widget>[
                      valueWidget,
                      AppCopyButton(
                        text: item.value!,
                        label: list.copyLabel!,
                        copiedLabel: list.copiedLabel,
                      ),
                    ],
                  )
                : valueWidget,
          ),
        ],
      ),
    );
  }
}
