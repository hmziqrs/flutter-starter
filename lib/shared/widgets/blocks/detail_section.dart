import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/blocks/detail_list.dart';

/// A titled detail group (detail-section.svelte): the section's name and
/// optional actions in one row, the description under them, and the content
/// in an outlined panel — the head and the description sit outside the
/// panel, 12dp apart (gap-3).
///
/// The panel brings the horizontal padding only (px-4), so an
/// [AppDetailList] lands flush inside it. A destructive tone draws the
/// panel's outline in destructive at 40%, for sections that remove things.
/// An optional [footer] rides the panel's foot under a 1px line, the way
/// the app settings section holds its form actions.
class AppDetailSection extends StatelessWidget {
  const AppDetailSection({
    required this.title,
    required this.items,
    this.description,
    this.actions = const [],
    this.tone = AppDetailSectionTone.defaultTone,
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

  /// The section's own actions, at the title's end — an outline "Edit", say.
  final List<Widget> actions;

  /// The panel's outline tone.
  final AppDetailSectionTone tone;

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

  /// An optional action row at the panel's foot, under a 1px line.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final destructive = tone == AppDetailSectionTone.destructive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The head row: the title and the actions at its end
        // (justify-between), wrapping 4dp apart.
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...<Widget>[
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
        if (description != null) ...<Widget>[
          // The block's gap-3 (12) between head, description and panel.
          const SizedBox(height: 12),
          ConstrainedBox(
            // max-w-prose: about 65 characters of a sentence.
            constraints: const BoxConstraints(maxWidth: 652),
            child: Text(
              description!,
              // The intro reads at the body size (APP-BLOCKS.md
              // DetailSection: text-sm text-muted-foreground).
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                // destructive draws the panel in destructive/40.
                color: destructive
                    ? theme.brand.destructive.withValues(alpha: 0.40)
                    : theme.colors.border,
                width: theme.style.borderWidth,
              ),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          // The panel brings the horizontal padding only; the list's rows
          // carry their own vertical air.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppDetailList(
                items: items,
                layout: layout,
                columns: columns,
                unsetText: unsetText,
                copyLabel: copyLabel,
                copiedLabel: copiedLabel,
              ),
              if (footer != null) ...<Widget>[
                Container(height: 1, color: theme.colors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: footer,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// How an [AppDetailSection]'s panel is outlined.
enum AppDetailSectionTone { defaultTone, destructive }
