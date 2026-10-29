import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// One tile of a bento grid (bento-tile.svelte): an outline tile with no
/// fill, no shadow and a transparent surface (BRAND.md s7 "Cards and icon
/// tiles have no grey fill"), its words top-start in the tile's corner —
/// never centered.
///
/// The word block follows the kit's rhythm: a 20dp inset (`p-5`), 6dp
/// between the lines (`gap-1.5`), the [eyebrow] in 13dp muted, the [title]
/// at 16dp w500 with -0.01em tracking, and the [body] in 14dp muted at
/// relaxed leading. Pass [child] alone for custom content (a mark, a chart,
/// a code tile); it sits where the words would.
///
/// Give [size] for a fixed square, or leave it null and the tile fills the
/// available width as a square ([AspectRatio]). Nothing here reacts to
/// hover — tiles are surfaces, not controls.
class BentoTile extends StatelessWidget {
  const BentoTile({
    this.child = const SizedBox.shrink(),
    this.size,
    this.padding,
    this.eyebrow,
    this.title,
    this.body,
    super.key,
  });

  /// The tile's custom content, under the words; a word-only tile needs
  /// nothing here.
  final Widget child;

  /// Fixed edge length; null fills the available width as a square.
  final double? size;

  /// Defaults to the kit's `p-5`: 20dp on every side.
  final EdgeInsetsGeometry? padding;

  /// The small muted line above the title, e.g. `freeoxide`.
  final String? eyebrow;

  /// The tile's heading, 16dp w500 with the kit's -0.01em tracking.
  final String? title;

  /// The tile's body, 14dp muted at relaxed leading.
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tile = Container(
      // The kit's word block: p-5 with a 6dp gap between lines, content
      // pinned to the tile's start corner (bento-tile.svelte p-5 gap-1.5).
      padding: padding ?? const EdgeInsets.all(20),
      alignment: AlignmentDirectional.topStart,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          // The tile's ring is the foreground at 10%
          // (bento-tile.svelte ring-1 ring-foreground/10).
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.10),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: <Widget>[
          if (eyebrow case final eyebrowText?)
            Text(
              eyebrowText,
              style: TextStyle(fontSize: 13, height: 1.2, color: theme.colors.mutedForeground),
            ),
          if (title case final titleText?)
            Text(
              titleText,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                letterSpacing: -0.01 * 16,
                fontWeight: FontWeight.w500,
                color: theme.colors.foreground,
              ),
            ),
          if (body case final bodyText?)
            Text(
              bodyText,
              style: TextStyle(
                fontSize: 14,
                height: 1.625,
                color: theme.colors.mutedForeground,
              ),
            ),
          child,
        ],
      ),
    );
    final fixedSize = size;
    return fixedSize == null
        ? AspectRatio(aspectRatio: 1, child: tile)
        : SizedBox(width: fixedSize, height: fixedSize, child: tile);
  }
}
