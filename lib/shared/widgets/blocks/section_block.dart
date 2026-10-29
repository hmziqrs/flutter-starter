import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// One titled part of a page (BRAND.md s8 "Section"): the section title at
/// 16 w500, an optional one-sentence intro in muted words, then the content
/// the page passes in.
///
/// Pure layout: no panel, no border of its own. Strings come from the caller
/// so pages can localize them.
class AppSectionBlock extends StatelessWidget {
  const AppSectionBlock({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  final String title;

  final String? description;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
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
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
