import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

// A floating pill dock for app chrome (a page's or a selection's few
// most-used actions): one frost pill, entries separated by hairlines, an
// optional lead text and one set-apart main action, exactly like the web
// kit's GlassDock (a Glass with rounded-full, p-1.5 and gap-1; the buttons
// are h-9 pills whose text is muted until hover or press). Below the web
// breakpoint where the kit's labels hide (`hidden sm:inline`, sm = 640px)
// the entries read icon-only, so the pill never pushes its main action off
// screen; the labels stay in semantics either way. The glass recipe
// comes from glass_style.dart; the dock only adds the pill shape and the
// entry anatomy.
//
// Nothing user-visible is hardcoded: every control's label comes from
// the caller, shown beside the icon at reading widths and carried as a
// semantics label either way, because an icon-only control must announce
// what it does. Hover and press are color only — foreground at 8% under the
// cursor, foreground at 10% while pressed, the way the web button's
// bg-foreground/8 and aria-pressed:bg-foreground/10 read — and focus draws
// the brand ring (primary at 50%, 3px). Nothing scales, lifts or translates.

/// One entry in a [GlassDock]'s row: an action, or a hairline separator
/// between groups of actions (glass-dock.svelte's `items: (Item |
/// "separator")[]`).
sealed class GlassDockEntry {
  const GlassDockEntry();
}

/// A hairline between groups of dock entries (the web kit's `mx-1 h-5 w-px
/// bg-border` span).
class GlassDockSeparator extends GlassDockEntry {
  const GlassDockSeparator();
}

/// One control in a [GlassDock].
class GlassDockAction extends GlassDockEntry {
  /// Creates an action; [semanticLabel] is required because an icon-only
  /// control must announce what it does.
  const GlassDockAction({
    required this.icon,
    required this.semanticLabel,
    this.label,
    this.onPressed,
    this.pressed = false,
  });

  /// The Lucide icon to draw (ForUI ships `FLucideIcons`).
  final IconData icon;

  /// The label written beside the icon at reading widths (glass-dock.svelte's
  /// `<span class="hidden sm:inline">{item.label}</span>`): hidden below the
  /// web kit's sm breakpoint (640px), where the kit reads icon-only, and
  /// still announced through [semanticLabel]. Null keeps an icon-only round
  /// control at every width, whose meaning must then ride entirely on
  /// [semanticLabel].
  final String? label;

  /// What the control does, announced to screen readers and required.
  final String semanticLabel;

  /// Called when the control is tapped or activated with Enter or Space;
  /// null disables the control (50% opacity, no interaction).
  final VoidCallback? onPressed;

  /// Whether the control is the active one (the web kit's `aria-pressed`):
  /// it reads its pill in foreground at 10% with a foreground icon, the way
  /// the reading dock's selected entry does.
  final bool pressed;
}

/// A floating pill dock: a row of icon controls inside a frost panel, with
/// optional lead words and one set-apart main action.
///
/// The dock is a glass surface like GlassPanel: one BackdropFilter, tight
/// clip, the same two recipe shadows (the web dock is a plain glass pill —
/// no extra depth), no nesting, nothing animated on interaction.
class GlassDock extends StatelessWidget {
  const GlassDock({
    required this.actions,
    this.lead,
    this.action,
    this.variant = GlassVariant.frost,
    this.padding,
    this.fallback = false,
    super.key,
  });

  /// The entries, laid out left to right; interleave [GlassDockSeparator]s
  /// to group them.
  final List<GlassDockEntry> actions;

  /// Words at the start, like "3 selected" (the web kit's `lead` snippet),
  /// followed by a hairline.
  final Widget? lead;

  /// A widget at the end, set apart behind a hairline: the one main action,
  /// like the web kit's primary button.
  final Widget? action;

  /// How much glass the dock carries; frost by default, like the web dock.
  final GlassVariant variant;

  /// Padding around the entry row; the web dock's 6px inset (p-1.5) by
  /// default.
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
                  padding: padding ?? const EdgeInsets.all(6), // web dock p-1.5
                  // Labeled controls (the web's reading-width dock) can exceed
                  // a narrow surface; the strip scrolls instead of clipping.
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4, // web dock gap-1
                      children: <Widget>[
                        if (lead case final Widget leadWidget) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            // The web lead span reads text-sm font-medium in
                            // the panel's foreground (glass-dock.svelte's
                            // `<span class="px-3 text-sm font-medium">`); the
                            // dock pins it so callers pass plain words.
                            child: DefaultTextStyle(
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colors.foreground,
                              ),
                              child: leadWidget,
                            ),
                          ),
                          const _GlassDockSeparator(),
                        ],
                        for (final entry in actions)
                          switch (entry) {
                            GlassDockAction() => _GlassDockButton(action: entry),
                            GlassDockSeparator() => const _GlassDockSeparator(),
                          },
                        if (action case final Widget actionWidget) ...<Widget>[
                          const _GlassDockSeparator(),
                          // No extra inset: the pill's own padding sits inside
                          // the dock's p-1.5, exactly like the web kit.
                          actionWidget,
                        ],
                      ],
                    ),
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

/// The hairline between entry groups: 1px wide, 20px tall, the theme border
/// color, 4px of air each side (mx-1 on top of the row's gap-1).
class _GlassDockSeparator extends StatelessWidget {
  const _GlassDockSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ColoredBox(
        color: context.theme.colors.border,
        child: const SizedBox(width: 1, height: 20),
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
  bool get _pressed => widget.action.pressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // The web button reads muted until it is pressed or under the cursor
    // (text-muted-foreground, hover:text-foreground,
    // aria-pressed:text-foreground).
    final active = _pressed || _hovered;
    // The web kit hides the label below its sm breakpoint
    // (`hidden sm:inline` on the label span, sm = 640px): the pill keeps its
    // main action on screen at phone widths and every entry still announces
    // itself through semantics.
    final labeled = widget.action.label != null && _showsLabels(context);
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
        selected: _pressed,
        label: widget.action.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.action.onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // A control is the web button's rounded-full pill at h-9: an
              // icon-only entry collapses to the same stadium (px-3 keeps the
              // kit's inset), a labeled one stretches.
              shape: labeled ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: labeled ? BorderRadius.circular(999) : null,
              // Press reads foreground/10, hover foreground/8, the web
              // button's aria-pressed and hover washes; pressed wins. The
              // border width is constant so the focus ring never shifts the
              // layout.
              color: _pressed
                  ? theme.colors.foreground.withValues(alpha: 0.1)
                  : _hovered && _enabled
                  ? theme.colors.foreground.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: Border.fromBorderSide(
                BorderSide(
                  color: _focused && _enabled
                      ? theme.colors.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: SizedBox(
              // The web button's h-9, icon-only controls included.
              height: 36,
              child: Padding(
                // The web button's px-3 on every control, icon-only included.
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Opacity(
                  opacity: _enabled ? 1 : 0.5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8, // the web button's gap-2 between icon and label
                    children: <Widget>[
                      Icon(
                        widget.action.icon,
                        size: 16, // the kit's [&_svg]:size-4
                        color: active ? theme.colors.foreground : theme.colors.mutedForeground,
                      ),
                      if (labeled)
                        Text(
                          widget.action.label!,
                          // The web button's text-sm, muted until hover or
                          // press.
                          style: theme.typography.body.sm.copyWith(
                            color: active ? theme.colors.foreground : theme.colors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether the ambient viewport has reached the web kit's sm breakpoint,
  /// where the kit's labels unhide (`hidden sm:inline`, sm = 640px).
  static bool _showsLabels(BuildContext context) => MediaQuery.sizeOf(context).width >= 640;
}
