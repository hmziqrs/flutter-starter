import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A square outline tile for grids (BRAND.md s7 "Cards and icon tiles have
/// no grey fill" and the bento grids of the SaaS landing patterns): a thin
/// theme line, a transparent fill, no shadow, square edges ratio.
///
/// Give [size] for a fixed square, or leave it null and the tile fills the
/// available width as a square ([AspectRatio]). Content is centered.
/// Nothing here reacts to hover — tiles are surfaces, not controls.
class BentoTile extends StatelessWidget {
  const BentoTile({required this.child, this.size, this.padding, super.key});

  final Widget child;

  /// Fixed edge length; null fills the available width as a square.
  final double? size;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tile = Container(
      alignment: Alignment.center,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: child,
    );
    final fixedSize = size;
    return fixedSize == null
        ? AspectRatio(aspectRatio: 1, child: tile)
        : SizedBox(width: fixedSize, height: fixedSize, child: tile);
  }
}
