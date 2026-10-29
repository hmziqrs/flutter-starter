import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A small muted sentence-case label (BRAND.md s5): the quiet line above a
/// title.
///
/// Never uppercase-spaced — the text renders exactly as given, so callers
/// keep sentence case and the label stays readable rather than shouty.
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Text(
      text,
      style: theme.typography.body.xs.copyWith(
        color: theme.colors.mutedForeground,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
