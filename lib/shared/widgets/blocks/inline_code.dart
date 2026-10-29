import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Inline code (BRAND.md s5): JetBrains Mono on the muted surface, in a
/// small rounded chip — for machine values inside a sentence, never for
/// emphasis.
class AppInlineCode extends StatelessWidget {
  const AppInlineCode(this.text, {this.fontSize = 13, super.key});

  final String text;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: theme.colors.muted,
        shape: RoundedSuperellipseBorder(borderRadius: theme.style.borderRadius.xs),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: fontSize,
          height: 1.25,
          color: theme.colors.foreground,
        ),
      ),
    );
  }
}
