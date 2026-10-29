import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/detail_list.dart';

/// A titled detail group (the detail kit's section variant): the section
/// title and optional intro over an [AppDetailList], all inside one thin
/// outline — the boxed unit a record page repeats, with an optional footer
/// action under the list.
class AppDetailSection extends StatelessWidget {
  const AppDetailSection({
    required this.title,
    required this.items,
    this.description,
    this.layout = AppDetailListLayout.rows,
    this.columns = 2,
    this.unsetText,
    this.copyLabel,
    this.copiedLabel,
    this.footer,
    super.key,
  });

  /// The section's title, at the 16 w500 section scale.
  final String title;

  /// The section's facts; passed straight to [AppDetailList].
  final List<AppDetailItem> items;

  /// One muted sentence under the title.
  final String? description;

  /// Rows or grid; passed straight to [AppDetailList].
  final AppDetailListLayout layout;

  /// Grid columns from the wide layout; 2 or 3.
  final int columns;

  /// What a missing value reads, e.g. "Not set".
  final String? unsetText;

  /// The copy button's rest label; required when an item is copyable.
  final String? copyLabel;

  /// The copy button's copied label.
  final String? copiedLabel;

  /// An optional action row under the list, above the box's bottom edge.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: theme.typography.body.md.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              description!,
              style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
          const SizedBox(height: 8),
          AppDetailList(
            items: items,
            layout: layout,
            columns: columns,
            unsetText: unsetText,
            copyLabel: copyLabel,
            copiedLabel: copiedLabel,
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(height: 1, color: theme.colors.border),
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}
