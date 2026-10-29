import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The top of an inner page (page-intro.svelte, at the app h1 scale): an
/// optional small grey kicker word, the title, and the one-sentence intro
/// under it.
///
/// The title is the app page's largest text at 24 w500 with tight tracking
/// (BRAND.md "App screens"); the intro runs muted at the body size. Stacked
/// with the block's gap-6 (24dp). No sections, no decoration — content
/// follows the caller.
class AppPageIntro extends StatelessWidget {
  const AppPageIntro({required this.title, this.kicker, this.description, super.key});

  /// The small grey word above the title, e.g. "Settings" — plain 13dp
  /// words, half a gap pulled up (page-intro.svelte's kicker, `-mb-2`).
  final String? kicker;

  final String title;

  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (kicker != null) ...<Widget>[
          Text(
            kicker!,
            // The kicker: text-[0.8125rem] muted, regular weight.
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
              fontSize: 13,
            ),
          ),
          // gap-6 minus the kicker's -mb-2: 24 - 8.
          const SizedBox(height: 16),
        ],
        Text(
          title,
          // The app page title: text-2xl font-medium tracking-tight
          // (tracking-tight = -0.025em).
          style: theme.typography.display.xl.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.025 * (theme.typography.display.xl.fontSize ?? 24),
          ),
        ),
        if (description != null) ...<Widget>[
          // The block's gap-6 between title and intro.
          const SizedBox(height: 24),
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
