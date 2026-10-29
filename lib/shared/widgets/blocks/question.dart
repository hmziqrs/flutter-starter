import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// The brand expandable question (question.svelte), a details-style row: the
/// ring sits hollow and grey while closed and fills primary when open, the
/// plus flips to a minus, and the answer shows under the row.
///
/// FAQ pages number them instead — `01`, `02`… in orange, no ring — and can
/// name a topic in a grey tag at the row's end. Feedback is color only; the
/// answer appears without animation, like the HTML `details` element this
/// block mirrors. Every row draws its own 1px line underneath
/// (question.svelte's `border-b`).
class AppQuestion extends StatefulWidget {
  const AppQuestion({
    required this.question,
    required this.answer,
    this.number,
    this.topic,
    this.initiallyOpen = false,
    this.onChanged,
    super.key,
  });

  final String question;

  final String answer;

  /// The one-based FAQ number; when set, `01`-style orange digits replace
  /// the ring (question.svelte's `number`).
  final int? number;

  /// The question's topic, shown as a grey tag at the row's end
  /// (question.svelte's `topic`).
  final String? topic;

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
    final numbered = widget.number != null;
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
                // The summary row's own air: 18dp above and below the
                // question (question.svelte: py-4.5) and none at the
                // sides — the ring and the line's ends align. Hover tints
                // the summary primary (`hover:text-primary`), ring
                // included: the marker takes the surrounding color.
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    side: _focused
                        ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 3)
                        : BorderSide.none,
                    borderRadius: theme.style.borderRadius.xs,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    if (numbered)
                      // Numbered FAQs: min-w-8 (32) of orange tabular
                      // digits instead of the ring.
                      SizedBox(
                        width: 32,
                        child: Text(
                          widget.number.toString().padLeft(2, '0'),
                          style: theme.typography.body.md.copyWith(
                            color: theme.colors.primary,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      )
                    else
                      AppRingMarker(
                        filled: _open,
                        color: _open || _hovering
                            ? theme.colors.primary
                            : theme.colors.mutedForeground,
                      ),
                    // gap-3 after the ring or the digits.
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        // The summary inherits the prose size in the svelte
                        // (16, font-medium) — the app section-title token.
                        style: theme.typography.body.md.copyWith(
                          color: _hovering ? theme.colors.primary : theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // A topic tag rides at the row's end (ml-auto) with the
                    // summary's own gap-3 before it; the plus keeps the gap
                    // and adds ml-3 — 24 together, as in the with-topic ref.
                    if (widget.topic != null) ...<Widget>[
                      const SizedBox(width: 12),
                      _TopicTag(topic: widget.topic!),
                      const SizedBox(width: 24),
                    ] else
                      const SizedBox(width: 12),
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
          ConstrainedBox(
            // max-w-2xl (672) covers the answer block including its inset.
            constraints: const BoxConstraints(maxWidth: 672),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                // The answer hangs under the question text: pl-5.5 (22) from
                // the row's edge, or pl-11 (44) — one ring plus the gap —
                // when numbered; pr-8 (32), pb-5 (20) (question.svelte).
                start: numbered ? 44 : 22,
                end: 32,
                bottom: 20,
              ),
              child: Text(
                widget.answer,
                // text-[0.9rem] leading-[1.7], muted.
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.mutedForeground,
                  fontSize: 14.4,
                  height: 1.7,
                ),
              ),
            ),
          ),
        // question.svelte draws border-b on every details row.
        Container(height: 1, color: theme.colors.border),
      ],
    );
  }
}

/// The question's grey topic tag (tag.svelte's plain variant): a 20dp soft
/// pill in the secondary fill, 12dp words.
class _TopicTag extends StatelessWidget {
  const _TopicTag({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: theme.colors.secondary,
        shape: const StadiumBorder(),
      ),
      child: Text(
        topic,
        style: theme.typography.body.xs.copyWith(
          color: theme.colors.secondaryForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A stack of [AppQuestion]s under one opening line (questions.svelte's
/// `border-t`); each question draws its own line underneath.
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
        Container(height: 1, color: theme.colors.border),
        for (final question in questions) question,
      ],
    );
  }
}
