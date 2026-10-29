import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The plain top of a page: its title and the one-sentence intro under it
/// (BRAND.md s8, app type scale).
///
/// The title is the page's largest text at 24 w500 with tight tracking; the
/// description runs muted at 14. No sections, no decoration — content
/// follows the caller.
class AppPageIntro extends StatelessWidget {
  const AppPageIntro({required this.title, this.description, super.key});

  final String title;

  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: theme.typography.display.xl.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02 * (theme.typography.display.xl.fontSize ?? 24),
          ),
        ),
        if (description != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            description!,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
