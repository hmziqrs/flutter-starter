import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// One titled part of a page (BRAND.md s8 "Section"): the section title at
/// 16 w500, an optional one-sentence intro in muted words, then the content
/// the page passes in.
///
/// The head stacks with the block's gap-3 (12dp) and the content follows a
/// full section gap (`gap-10`, 40dp) below. Pure layout: no panel, no border
/// of its own. Strings come from the caller so pages can localize them.
class AppSectionBlock extends StatelessWidget {
  const AppSectionBlock({
    required this.title,
    required this.child,
    this.description,
    this.gap = 40,
    super.key,
  });

  final String title;

  final String? description;

  final Widget child;

  /// The space before the content: the kit's `gap-10` on content pages. App
  /// screens pass a tighter one, so a heading stays with what it heads.
  final double gap;

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
          // The head's gap-3.
          const SizedBox(height: 12),
          Text(
            description!,
            // The intro reads muted at the body size (app descriptions are
            // text-sm).
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
        SizedBox(height: gap),
        child,
      ],
    );
  }
}
