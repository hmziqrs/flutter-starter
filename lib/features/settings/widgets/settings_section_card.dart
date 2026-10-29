import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// One titled part of a settings page (APP-BLOCKS.md "SettingsSection"): a
/// 16 w500 sentence-case title and an optional muted description above an
/// outlined panel whose rows are separated by 1px hairlines.
///
/// The panel is an outline only (BRAND.md s8, s13): a 1px border, a
/// transparent fill, no shadow — only floating overlays get a card fill.
/// Rows carry their own padding; the card only draws the panel and the
/// hairlines between rows, so hover and selection stay color changes the
/// rows themselves make.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.children,
    this.title,
    this.description,
    super.key,
  });

  /// The section title, never uppercase (BRAND.md s5). Null when the page
  /// title already names the only group on the page.
  final String? title;

  /// One muted sentence under the title.
  final String? description;

  /// The panel's rows.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final hasHeader = title != null || description != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader) ...[
          if (title != null)
            Text(
              title!,
              style: theme.typography.body.md.copyWith(fontWeight: FontWeight.w500),
            ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
          const SizedBox(height: 12),
        ],
        DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0) Container(height: 1, color: theme.colors.border),
                  children[index],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
