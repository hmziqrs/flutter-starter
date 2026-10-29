import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// The brand expandable question (BRAND.md s8 "Questions"), a details-style
/// row: the ring sits hollow and grey while closed and fills primary when
/// open, the plus flips to a minus, and the answer shows under the row.
///
/// Feedback is color only; the answer appears without animation, like the
/// HTML `details` element this block mirrors. Rows sit under 1px lines.
class AppQuestion extends StatefulWidget {
  const AppQuestion({
    required this.question,
    required this.answer,
    this.initiallyOpen = false,
    this.onChanged,
    super.key,
  });

  final String question;

  final String answer;

  final bool initiallyOpen;

  /// Called with the new open state after each toggle.
  final ValueChanged<bool>? onChanged;

  @override
  State<AppQuestion> createState() => _AppQuestionState();
}

class _AppQuestionState extends State<AppQuestion> {
  late bool _open = widget.initiallyOpen;
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    widget.onChanged?.call(_open);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FocusableActionDetector(
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
                _toggle();
                return null;
              },
            ),
          },
          child: Semantics(
            button: true,
            expanded: _open,
            child: GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: ShapeDecoration(
                  color: _hovering ? theme.colors.muted : null,
                  shape: RoundedSuperellipseBorder(
                    side: _focused
                        ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                        : BorderSide.none,
                    borderRadius: theme.style.borderRadius.xs,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    AppRingMarker(
                      filled: _open,
                      color: _open ? theme.colors.primary : theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _open ? FLucideIcons.minus : FLucideIcons.plus,
                      size: 16,
                      color: theme.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 12, start: 19),
            child: Text(
              widget.answer,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }
}

/// A stack of [AppQuestion]s separated by 1px lines (never doubled).
class AppQuestions extends StatelessWidget {
  const AppQuestions({required this.questions, super.key});

  final List<AppQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < questions.length; index++) ...<Widget>[
          if (index > 0) Container(height: 1, color: theme.colors.border),
          questions[index],
        ],
      ],
    );
  }
}
