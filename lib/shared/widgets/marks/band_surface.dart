import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// The quiet gray band (`.band-gray`, BRAND.md s7 "Bands"): a full-width
/// section in the mode's quiet neutral for numbers or a group of cards,
/// with square edges and no border.
///
/// The band token maps to the neutrals the theme already carries: the card
/// neutral in dark mode, the muted neutral in light mode. Content keeps the
/// page's text colors — the band changes the surface, nothing else. The
/// orange `CtaBand` is the only colored section; this one is grey.
class BandSurface extends StatelessWidget {
  const BandSurface({required this.child, this.padding, super.key});

  final Widget child;

  /// The band's own padding; leave null to let the caller's container
  /// handle the rhythm (the band itself is edge to edge).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final bandColor = colors.brightness == Brightness.dark ? colors.card : colors.muted;
    return Container(
      width: double.infinity,
      padding: padding,
      color: bandColor,
      child: child,
    );
  }
}
