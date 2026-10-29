import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The site's name in the brand wordmark: semibold type with tight tracking,
/// ending in a trailing solid orange square (BRAND.md s7).
///
/// Sized by [fontSize]; the square scales with it at `0.36em` and paints the
/// theme's primary (wordmark.svelte's `bg-primary`: the mode's orange while
/// the accent is oxide — F38230 dark, AA530A light). The always-bright
/// `--mark-square` belongs to the Mark tile, not the wordmark. The optional
/// [makerLine] ("by hmziq") renders at `0.78em` in muted foreground. The
/// letters never carry a color other than the theme foreground, and nothing
/// here reacts to hover.
class AppWordmark extends StatelessWidget {
  const AppWordmark({
    required this.name,
    this.makerLine,
    this.fontSize = 18,
    this.showSquare = true,
    super.key,
  });

  final String name;

  final String? makerLine;

  final double fontSize;

  final bool showSquare;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final squareExtent = fontSize * 0.36;
    // The square rides inline in the name's text flow as a baseline
    // placeholder: its bottom edge sits on the alphabetic baseline, the s7
    // recipe's inline square. (A Row baseline pin drops baseline-less
    // children on the row's top edge, which reads as a superscript.)
    //
    // The square color is `bg-primary` (wordmark.svelte:44): the theme's
    // primary, which the factory points at the accent — the mode's orange
    // under the brand accent, and the re-pointed color if an accent ever
    // overrides it (BRAND.md s4, "Changing colors").
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: name),
              if (showSquare)
                WidgetSpan(
                  alignment: PlaceholderAlignment.aboveBaseline,
                  baseline: TextBaseline.alphabetic,
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: fontSize * 0.07),
                      child: SizedBox(
                        width: squareExtent,
                        height: squareExtent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -0.02 * fontSize,
            color: colors.foreground,
          ),
        ),
        if (makerLine != null)
          Padding(
            // The maker story's gap-[0.35em] between name and "by hmziq".
            padding: EdgeInsetsDirectional.only(start: fontSize * 0.35),
            child: Text(
              makerLine!,
              style: TextStyle(
                fontSize: fontSize * 0.78,
                color: colors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }
}
