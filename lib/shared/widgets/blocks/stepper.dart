import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// One step of an [AppStepper].
typedef AppStepperStep = ({String label, String? description});

/// The brand stepper (BRAND.md s8): 36dp rings with 1.75px borders joined by
/// a 1px line, drawn vertically so labels sit beside their step.
///
/// A done step fills primary and the line below it turns primary. The
/// current step is a hollow primary ring; upcoming steps are muted. Steps
/// are numbered only when the order is real. Feedback is color only —
/// nothing moves on hover, press or focus — and the focus ring is primary.
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
        for (var index = 0; index < steps.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 4),
          _StepperRow(
            step: steps[index],
            index: index,
            state: _stepState(index),
            isLast: index == steps.length - 1,
            onTap: onStepTap == null ? null : () => onStepTap!(index),
          ),
        ],
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
    final ringColor = switch (widget.state) {
      _StepState.done => brand.oxide,
      _StepState.current => brand.oxide,
      _StepState.upcoming => theme.colors.border,
    };
    final numberColor = switch (widget.state) {
      _StepState.done => brand.onOrange,
      _StepState.current => brand.oxide,
      _StepState.upcoming => theme.colors.mutedForeground,
    };
    final labelColor = widget.state == _StepState.upcoming
        ? theme.colors.mutedForeground
        : theme.colors.foreground;
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
            // primary focus ring at half strength. Nothing translates.
            color: _hovering && interactive ? theme.colors.muted : null,
            shape: RoundedSuperellipseBorder(
              side: _focused && interactive
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                  : BorderSide.none,
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      style: theme.typography.body.xs.copyWith(
                        color: numberColor,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                  if (!widget.isLast)
                    Container(
                      width: 1,
                      height: 20,
                      color: done ? brand.oxide : theme.colors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.step.label,
                        style: theme.typography.body.sm.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.step.description != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          widget.step.description!,
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
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
    );
  }
}
