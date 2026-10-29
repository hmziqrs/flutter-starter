import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

// A floating pill dock for app chrome (a music bar, a floating toolbar): a
// row of icon controls inside a frost panel with a deeper shadow than a
// panel carries. The recipe comes from glass_style.dart; the dock only adds
// the pill radius and the stronger shadow.
//
// Nothing user-visible is hardcoded: every control's label comes from the
// caller as a semantics label, because an icon-only control must announce
// what it does. Hover and press are color only (the tile tints to the muted
// color); focus draws the brand ring (primary at 50%, 3px); nothing scales,
// lifts or translates.

/// One icon control in a [GlassDock].
class GlassDockAction {
  /// Creates an action; [semanticLabel] is required because an icon-only
  /// control must announce what it does.
  const GlassDockAction({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  /// The Lucide icon to draw (ForUI ships `FLucideIcons`).
  final IconData icon;

  /// What the control does, announced to screen readers and required.
  final String semanticLabel;

  /// Called when the control is tapped or activated with Enter or Space;
  /// null disables the control (50% opacity, no interaction).
  final VoidCallback? onPressed;
}

/// A floating pill dock: a row of icon controls inside a frost panel with a
/// stronger shadow, for floating app chrome.
///
/// The dock is a glass surface like GlassPanel: one BackdropFilter, tight
/// clip, no nesting, nothing animated on interaction.
class GlassDock extends StatelessWidget {
  const GlassDock({
    required this.actions,
    this.variant = GlassVariant.frost,
    this.padding,
    this.fallback = false,
    super.key,
  });

  /// The icon controls, laid out left to right.
  final List<GlassDockAction> actions;

  /// How much glass the dock carries; frost by default.
  final GlassVariant variant;

  /// Padding around the control row; the dock's own 8px inset by default.
  final EdgeInsetsGeometry? padding;

  /// The honest degraded path: solid card fill, same border and shine, no
  /// blur layer at all.
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    assert(() {
      GlassScope.debugAssertNotNested(context, 'GlassDock');
      return true;
    }(), 'GlassDock must not sit inside another glass surface');
    final theme = context.theme;
    final style = GlassSurfaceStyle.resolve(
      variant: variant,
      theme: theme,
      radius: theme.style.borderRadius.pill,
      dockShadow: true,
      fallback: fallback,
    );
    return GlassScope(
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: style.radius,
            boxShadow: style.shadows,
          ),
          child: ClipRRect(
            borderRadius: style.radius,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: style.usesBackdropFilter
                      ? BackdropFilter(
                          filter: style.backdropFilter,
                          child: ColoredBox(color: style.wash),
                        )
                      : ColoredBox(color: style.wash),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: GlassEdgePainter(style: style)),
                ),
                Padding(
                  padding: padding ?? const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: <Widget>[
                      for (final action in actions) _GlassDockButton(action: action),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDockButton extends StatefulWidget {
  const _GlassDockButton({required this.action});

  final GlassDockAction action;

  @override
  State<_GlassDockButton> createState() => _GlassDockButtonState();
}

class _GlassDockButtonState extends State<_GlassDockButton> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.action.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.action.onPressed?.call();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: widget.action.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.action.onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Hover is a color change only; the border width is constant so
              // the focus ring never shifts the layout.
              color: _hovered && _enabled ? theme.colors.muted : Colors.transparent,
              border: Border.fromBorderSide(
                BorderSide(
                  color: _focused && _enabled
                      ? theme.colors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Opacity(
                opacity: _enabled ? 1 : 0.5,
                child: Icon(
                  widget.action.icon,
                  size: 20,
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
