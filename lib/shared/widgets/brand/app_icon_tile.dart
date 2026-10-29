import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The brand icon tile (BRAND.md s9): a square that holds one icon, radius 8,
/// icon drawn at half the tile size.
///
/// Without a [tone] it is the signature outline tile: a thin theme border, no
/// fill, and the icon in primary. A [tone] fills it softly with that color at
/// 10% (20% in dark) and drops the border — the brand's softTone recipe, one
/// color per tile. [iconColor] instead keeps the outline tile and colors only
/// the icon, the app states recipe ("the icon carries the color, the tile
/// stays an outline"). [tone] wins when both are given.
class AppIconTile extends StatelessWidget {
  const AppIconTile({required this.icon, this.tone, this.iconColor, this.size = 36, super.key});

  final IconData icon;

  final Color? tone;

  final Color? iconColor;

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final softFill = tone?.withValues(
      alpha: theme.colors.brightness == Brightness.dark ? 0.20 : 0.10,
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: softFill ?? Colors.transparent,
        // The brand's rounded-md is a plain circular arc, not a squircle.
        shape: RoundedRectangleBorder(
          side: softFill == null
              ? BorderSide(color: theme.colors.border, width: theme.style.borderWidth)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Icon(icon, size: size / 2, color: tone ?? iconColor ?? theme.colors.primary),
    );
  }
}
