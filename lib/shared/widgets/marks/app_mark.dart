import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// The site's two-letter mark (BRAND.md s7 "Mark"): [symbol] and the orange
/// square on a rounded tile painted in the opposite of the page color — the
/// tile is the theme foreground, the letters the theme background — so it
/// reads as an avatar, favicon stand-in or "More from hmziq" tile.
///
/// Geometry scales from [size]: corner radius at 22% of the tile, letters at
/// 0.42 of the tile in w600 with -0.02em tracking (of the tile size, as the
/// CSS computed value inherits), the square always the bright `markSquare`
/// orange at 0.3 em of the letters (0.126 of the tile) with a 0.07 em gap
/// (0.0294 of the tile) — the web recipe's `size-[0.3em]`/`ml-[0.07em]`
/// resolve inside the `text-[0.42em]` letter span. No rings, no outlines, no
/// texture on the mark (BRAND.md s13).
///
/// Favicon and app-icon raster files default dark: they draw the light-mode
/// tile — white #FAFAFA, near-black #0A0A0A letters, #F38230 square — since
/// icon files sit on unknown backgrounds.
///
/// [squareLabel] is the accessibility label announced for the whole mark;
/// the drawn letters and square are decorative (the web mark is
/// `aria-hidden` and the surrounding name carries the meaning).
class AppMark extends StatelessWidget {
  const AppMark({
    required this.symbol,
    required this.squareLabel,
    this.size = 20,
    super.key,
  });

  /// The two-letter symbol drawn on the tile, e.g. `Hq`.
  final String symbol;

  /// The accessibility label announced for the mark.
  final String squareLabel;

  /// The tile's edge length; every other measure derives from it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final brand = context.theme.brand;
    // The square and its gap live in em of the letters (0.42 of the tile),
    // like the web mark's size-[0.3em]/ml-[0.07em] inside text-[0.42em].
    final letterFontSize = size * 0.42;
    final squareExtent = letterFontSize * 0.3;
    return Semantics(
      label: squareLabel,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: colors.foreground,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        // The letter row keeps its natural width: real typefaces fit inside
        // the tile, and a wider fallback face simply clips at the tile edge.
        // The square rides inline in the letters' text flow as a baseline
        // placeholder: its bottom edge sits on the alphabetic baseline, like
        // the web recipe's inline-block square. (A Row baseline pin drops
        // baseline-less children on the row's top edge, a superscript.)
        child: OverflowBox(
          minWidth: 0,
          maxWidth: double.infinity,
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(text: symbol),
                WidgetSpan(
                  alignment: PlaceholderAlignment.aboveBaseline,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(start: letterFontSize * 0.07),
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
              fontSize: letterFontSize,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.02 * size,
              color: colors.background,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
