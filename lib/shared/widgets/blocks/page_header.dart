import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The top of an app screen (app-page-header.svelte): the 24 w500 tight title
/// and one muted line close under it, 6dp away, held to a reading measure.
///
/// `AppPageIntro` is the content-page version, with a wider gap. App screens
/// use this one, so the words read as a single block.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.description,
    this.titleKey,
    this.descriptionKey,
    this.gap = 6,
    super.key,
  });

  final String title;

  final String? description;

  final Key? titleKey;

  final Key? descriptionKey;

  /// The space between the title and its line. The auth layout's header uses
  /// the kit's `gap-2` (8); app screens its `mt-1.5` (6).
  final double gap;

  /// The kit's `max-w-prose` on the description.
  static const double _descriptionMaxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final display = theme.typography.display.xl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          key: titleKey,
          style: display.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.025 * (display.fontSize ?? 24),
          ),
        ),
        if (description != null) ...<Widget>[
          SizedBox(height: gap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _descriptionMaxWidth),
            child: Text(
              description!,
              key: descriptionKey,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ),
        ],
      ],
    );
  }
}
