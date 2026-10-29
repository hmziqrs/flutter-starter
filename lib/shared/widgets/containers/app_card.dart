import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

/// Brand outline card: transparent fill, a 1px theme border, no shadow.
///
/// Surfaces that sit in the page are outline only (BRAND.md s8, s13); only
/// floating overlays get a fill and shadow. Hover feedback is a color change
/// alone (BRAND.md s10): the border tints toward primary at 50% opacity and
/// nothing moves, lifts or scales.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.style = const FCardStyleDelta.context(),
    this.clipBehavior = Clip.none,
    super.key,
  });

  final EdgeInsetsGeometry? padding;

  final FCardStyleDelta style;

  final Clip clipBehavior;

  final Widget child;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final outlineStyle = _outlineStyle(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FCard(
        style: widget.style(outlineStyle),
        clipBehavior: widget.clipBehavior,
        child: Padding(
          padding: widget.padding ?? EdgeInsets.all(context.presentationTokens.cardPadding),
          child: widget.child,
        ),
      ),
    );
  }

  /// The theme card style with its decoration replaced by the brand outline:
  /// a transparent fill and a 1px border that tints toward primary on hover.
  FCardStyle _outlineStyle(BuildContext context) {
    final theme = context.theme;
    final borderColor = _hovered
        ? theme.colors.primary.withValues(alpha: 0.5)
        : theme.colors.border;
    // Minimal dependent fix from the settings-profile area to keep the tree
    // compiling: the delta factory lives on FCardStyleDelta, and a null fill
    // paints nothing (transparent).
    return FCardStyleDelta.delta(
      decoration: DecorationDelta.value(
        ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: borderColor, width: theme.style.borderWidth),
            borderRadius: theme.style.borderRadius.lg,
          ),
        ),
      ),
    )(theme.cardStyle);
  }
}
