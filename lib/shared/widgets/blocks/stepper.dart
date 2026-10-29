import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// One step of an [AppStepper].
typedef AppStepperStep = ({String label, String? description});

/// The brand stepper (BRAND.md s8): 36dp rings with 1.75px borders joined by
/// a 1px line, drawn vertically so labels sit beside their step (stepper,
/// step and step-number svelte).
///
/// A done step fills primary and its line turns primary; every step still to
/// do — the current one included — sits hollow on the border color with a
/// muted number (step-number.svelte has only the two states, and the
/// in-progress storybook ref shows the pending ring grey). Steps are
/// numbered only when the order is real. Feedback is color only — nothing
/// moves on hover, press or focus — and the focus ring is primary.
class AppStepper extends StatelessWidget {
  const AppStepper({
    required this.steps,
    required this.currentStep,
    this.onStepTap,
    super.key,
  });

  /// The steps in order; each carries its own label and optional
  /// description from the caller.
  final List<AppStepperStep> steps;

  /// The zero-based step the user is on. Steps before it are done.
  final int currentStep;

  /// Called with a step's index when the user activates it; leave null for
  /// a read-only stepper.
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < steps.length; index++)
          _StepperRow(
            step: steps[index],
            index: index,
            state: _stepState(index),
            isLast: index == steps.length - 1,
            onTap: onStepTap == null ? null : () => onStepTap!(index),
          ),
      ],
    );
  }

  _StepState _stepState(int index) {
    if (index < currentStep) {
      return _StepState.done;
    }
    if (index == currentStep) {
      return _StepState.current;
    }
    return _StepState.upcoming;
  }
}

enum _StepState { done, current, upcoming }

class _StepperRow extends StatefulWidget {
  const _StepperRow({
    required this.step,
    required this.index,
    required this.state,
    required this.isLast,
    this.onTap,
  });

  final AppStepperStep step;

  final int index;

  final _StepState state;

  final bool isLast;

  final VoidCallback? onTap;

  @override
  State<_StepperRow> createState() => _StepperRowState();
}

class _StepperRowState extends State<_StepperRow> {
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
    final brand = theme.brand;
    final done = widget.state == _StepState.done;
    // The brand knows two states (step-number.svelte): done fills primary,
    // everything still to do sits hollow on the border with a muted number.
    final ringColor = done ? brand.oxide : theme.colors.border;
    final numberColor = done ? brand.onOrange : theme.colors.mutedForeground;
    final interactive = widget.onTap != null;

    return FocusableActionDetector(
      mouseCursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: interactive ? (hovering) => setState(() => _hovering = hovering) : null,
      onShowFocusHighlight: interactive ? (focused) => setState(() => _focused = focused) : null,
      focusNode: interactive ? _focusNode : null,
      shortcuts: interactive
          ? const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : null,
      actions: interactive
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onTap!();
                  return null;
                },
              ),
            }
          : null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: ShapeDecoration(
            // Hover and focus are color changes only: a muted wash, or the
            // primary focus ring at half strength (svelte: ring-3 at 50%).
            // Nothing translates.
            color: _hovering && interactive ? theme.colors.muted : null,
            shape: RoundedSuperellipseBorder(
              side: _focused && interactive
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 3)
                  : BorderSide.none,
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          // Rows stack with no outer gap: the air between steps lives inside
          // the row, so the connector line reaches down through it the way
          // the svelte step's `pb-9` does.
          padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
          // The connector line joins the rings across the whole step gap, the
          // way the svelte step's line runs from under one ring to the next.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: done ? brand.oxide : Colors.transparent,
                        shape: CircleBorder(
                          side: BorderSide(color: ringColor, width: 1.75),
                        ),
                      ),
                      child: Text(
                        '${widget.index + 1}',
                        style: theme.typography.body.sm.copyWith(
                          color: numberColor,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                    if (!widget.isLast) ...<Widget>[
                      // The line starts 6dp under the ring and stops 6dp
                      // short of the next one (step.svelte: top-[2.6rem],
                      // bottom-1.5).
                      const SizedBox(height: 6),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 1, minHeight: 20),
                          width: 1,
                          color: done ? brand.oxide : theme.colors.border,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    // Content hangs 6dp from the ring's top (pt-1.5) and
                    // carries the full 36dp step gap below it (pb-9,
                    // last:pb-0) — the same air the line column ends with.
                    padding: EdgeInsetsDirectional.only(
                      top: 6,
                      bottom: widget.isLast ? 0 : 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.step.label,
                          // Step titles read at the story's size
                          // (stepper.stories: text-[1.0625rem]
                          // font-medium); every title stays in the
                          // foreground, done or not.
                          style: theme.typography.body.md.copyWith(
                            color: theme.colors.foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.step.description != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            widget.step.description!,
                            // The story's body: text-[0.9rem]
                            // leading-relaxed, muted.
                            style: theme.typography.body.sm.copyWith(
                              color: theme.colors.mutedForeground,
                              fontSize: 14.4,
                              height: 1.625,
                            ),
                          ),
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
