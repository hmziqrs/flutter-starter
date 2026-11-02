import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Inline code (BRAND.md s5): JetBrains Mono on the muted surface, in a
/// small rounded chip — for machine values inside a sentence, never for
/// emphasis.
///
/// The chip runs at 0.9em of the 14dp sentence around it (inline-code.svelte:
/// `text-[0.9em]` on a `text-sm` parent) on the page's 1.5 leading, so the
/// chip lands at the reference's 23dp (18.9 line + 4dp of air).
class AppInlineCode extends StatelessWidget {
  const AppInlineCode(this.text, {this.fontSize = 12.6, super.key});

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
          height: 1.5,
          color: theme.colors.foreground,
        ),
      ),
    );
  }
}
