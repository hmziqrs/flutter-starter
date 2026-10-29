import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The wordmark's end mark on its own (BRAND.md s7): a solid orange square,
/// sized in em of the surrounding text at 0.36 — the same ratio the
/// `AppWordmark` square uses — so it sits next to type of any size and
/// scales with it.
///
/// It paints the theme's primary, like the wordmark's `bg-primary`
/// (wordmark.svelte:44): the mode's orange while the accent is oxide —
/// F38230 dark, AA530A light. The always-bright `markSquare` belongs to the
/// Mark tile, not the wordmark's square. Always square, always decorative:
/// pair it with real text that carries the meaning.
class LogoSquare extends StatelessWidget {
  const LogoSquare({super.key});

  @override
  Widget build(BuildContext context) {
    final ambientFontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    final extent = ambientFontSize * 0.36;
    return ExcludeSemantics(
      child: SizedBox(
        width: extent,
        height: extent,
        child: ColoredBox(color: context.theme.colors.primary),
      ),
    );
  }
}
