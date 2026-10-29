import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// The signature (BRAND.md s7 "Wordmark" footer recipe): the site's
/// [name] ending in a solid orange square, laid out at a computed font
/// size so name and square together span the container width, clipped,
/// under a thin top border with generous top padding and a small
/// [copyright] line under it.
///
/// The web recipe sets the wordmark at `text-[33cqw] leading-[0.74]
/// tracking-[-0.05em]` inside an `overflow-hidden border-t pt-10` wrapper
/// with `pb-[0.2em]`; here the font size is measured with a [TextPainter]
/// at a reference size and scaled so the wordmark plus its square and gap
/// fill exactly the measured width. The letters keep the wordmark weight
/// (w600, never heavier) and the square keeps the bright `markSquare`
/// orange in both modes.
class SignatureFooter extends StatelessWidget {
  const SignatureFooter({required this.name, required this.copyright, super.key});

  /// The site's name, e.g. `hmziq`.
  final String name;

  /// The small copyright line under the signature, e.g. `© 2026 hmziq.`.
  final String copyright;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    // The measured and rendered styles must share a typeface or the span
    // drifts: take the ambient family (Onest in production).
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final fontSize = _fontSizeForWidth(name, width, fontFamily);
        final squareExtent = fontSize * 0.36;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
                ),
              ),
              padding: const EdgeInsets.only(top: 40),
              child: ClipRect(
                child: Padding(
                  // The 0.74 line box is shorter than the glyphs; the 0.2em
                  // foot keeps descenders and the square inside the clip,
                  // exactly like the web recipe's pb-[0.2em].
                  padding: EdgeInsets.only(bottom: fontSize * 0.2),
                  // Keeps its natural width (measured to span the
                  // container); the clip is the backstop for any drift. The
                  // square rides inline in the name's text flow as a
                  // baseline placeholder: its bottom edge sits on the
                  // alphabetic baseline, the s7 recipe's inline square.
                  // (A Row baseline pin drops baseline-less children on the
                  // row's top edge, which reads as a superscript.)
                  child: UnconstrainedBox(
                    constrainedAxis: Axis.vertical,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text.rich(
                      TextSpan(
                        text: name,
                        children: <InlineSpan>[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.aboveBaseline,
                            baseline: TextBaseline.alphabetic,
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: fontSize * 0.07),
                              child: SizedBox(
                                width: squareExtent,
                                height: squareExtent,
                                child: ColoredBox(color: brand.markSquare),
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        height: 0.74,
                        letterSpacing: -0.05 * fontSize,
                        leadingDistribution: TextLeadingDistribution.even,
                        color: theme.colors.foreground,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              copyright,
              style: TextStyle(fontSize: 14, height: 1.35, color: theme.colors.mutedForeground),
            ),
          ],
        );
      },
    );
  }

  /// Measures [name] at a reference size (same weight, tracking and line
  /// height as the render) and scales it so name + gap + square span
  /// exactly [width].
  double _fontSizeForWidth(String name, double width, String? fontFamily) {
    const reference = 100.0;
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          fontSize: reference,
          fontWeight: FontWeight.w600,
          height: 0.74,
          letterSpacing: -0.05 * reference,
          leadingDistribution: TextLeadingDistribution.even,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final spannedWidth = painter.width + reference * (0.36 + 0.07);
    // Truncating keeps the drawn row a hair under the container width, so
    // measurement rounding never flags an overflow against the clip.
    return (width * reference / spannedWidth * 1000).floorToDouble() / 1000;
  }
}
