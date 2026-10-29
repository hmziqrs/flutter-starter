import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// One option of an [AppSegmented] control.
typedef AppSegmentOption<T> = ({T value, String label});

/// The brand segmented control (BRAND.md s8): a thin outline around the
/// options; the picked one gets the soft primary fill — primary at 10%,
/// 20% in dark — with primary text.
///
/// Feedback is color only: hover tints a segment with the muted surface,
/// focus draws the primary ring, and nothing ever moves. Heights follow the
/// 32dp touch floor.
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
    return Container(
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.sm,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < options.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 2),
            _Segment(
              label: options[index].label,
              selected: options[index].value == value,
              isDark: theme.colors.brightness == Brightness.dark,
              onTap: () => onChanged(options[index].value),
            ),
          ],
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: widget.selected
                ? theme.colors.primary.withValues(alpha: fillOpacity)
                : _hovering
                ? theme.colors.muted
                : Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: _focused
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                  : BorderSide.none,
              borderRadius: theme.style.borderRadius.xs,
            ),
          ),
          child: Text(
            widget.label,
            style: theme.typography.body.sm.copyWith(
              color: widget.selected ? theme.colors.primary : theme.colors.mutedForeground,
              fontWeight: widget.selected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
