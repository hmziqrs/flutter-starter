import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The brand icon tile (BRAND.md s9): an outline tile at [size] with the icon
/// drawn at half the tile size in [tone], defaulting to the theme primary.
///
/// A thin line and no fill, like every surface that sits in the page. Pass a
/// [tone] only when the color means something; a group of equal tiles keeps
/// one color.
class AppIconTile extends StatelessWidget {
  const AppIconTile({required this.icon, this.tone, this.size = 36, super.key});

  final IconData icon;

  final Color? tone;

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(
            color: theme.colors.border,
            width: theme.style.borderWidth,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Icon(icon, size: size / 2, color: tone ?? theme.colors.primary),
    );
  }
}
