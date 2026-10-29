import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// One option of an [AppSegmented] control. The optional [Key] lands on the
/// segment's widget so pages and tests can address individual options.
typedef AppSegmentOption<T> = ({T value, String label, Key? key});

/// The brand segmented control (BRAND.md s8): a thin outline around the
/// options; the picked one gets the soft primary fill — primary at 10%,
/// 20% in dark — with primary text.
///
/// Feedback is color only: hover tints a segment with the muted surface,
/// focus draws the primary ring, and nothing ever moves. Segments are the
/// svelte's h-7.5 (30dp) pills.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<AppSegmentOption<T>> options;

  /// The currently picked option's value.
  final T value;

  /// Called with the newly picked value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // Root: a thin outline with 4dp padding and 4dp between options. The
    // svelte container is rounded-[calc(var(--radius-md)+4px)] — the theme's
    // radius-md is 8, so 12; no token holds 12, hence the explicit radius.
    // The options wrap inside the outline — one line wherever the control
    // fits, never a horizontal overflow on narrow panes or at large text
    // sizes.
    return Container(
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          for (var index = 0; index < options.length; index++)
            _Segment(
              key: options[index].key,
              label: options[index].label,
              selected: options[index].value == value,
              isDark: theme.colors.brightness == Brightness.dark,
              onTap: () => onChanged(options[index].value),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatefulWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  final String label;

  final bool selected;

  final bool isDark;

  final VoidCallback onTap;

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final fillOpacity = widget.isDark ? 0.20 : 0.10;
    return FocusableActionDetector(
      focusNode: _focusNode,
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (hovering) => setState(() => _hovering = hovering),
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // The svelte segment is h-7.5 (30) with px-3 and text at 13.
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            // The picked segment carries the soft primary fill; resting and
            // hovered ones stay unfilled — the svelte hover is
            // `hover:text-foreground`, a text-color change only.
            color: widget.selected
                ? theme.colors.primary.withValues(alpha: fillOpacity)
                : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: _focused
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 3)
                  : BorderSide.none,
              // Brand rounded-md controls (theme sm is the 8dp match).
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          child: Text(
            widget.label,
            // Every segment label is text-[0.8125rem] font-medium
            // (segmented.svelte), so the picked one moves by color alone:
            // picked text goes primary, a hovered resting one to the
            // foreground, the rest stay muted.
            style: theme.typography.body.sm.copyWith(
              color: widget.selected
                  ? theme.colors.primary
                  : _hovering
                  ? theme.colors.foreground
                  : theme.colors.mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
