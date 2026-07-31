import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    required this.isBusy,
    required this.child,
    this.label,
    this.semanticsLabel,
    this.value,
    super.key,
  });

  final bool isBusy;

  final Widget child;

  final String? label;

  final String? semanticsLabel;

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        if (isBusy)
          Positioned.fill(
            child: _BusyBarrier(
              label: label,
              semanticsLabel: semanticsLabel,
              value: value,
              key: const ValueKey('busy-overlay-barrier'),
            ),
          ),
      ],
    );
  }
}

class _BusyBarrier extends StatelessWidget {
  const _BusyBarrier({this.label, this.semanticsLabel, this.value, super.key});

  final String? label;
  final String? semanticsLabel;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.common;
    final resolvedLabel = label ?? translations.saving;
    final resolvedSemantics = semanticsLabel ?? resolvedLabel;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget content;
    if (reduceMotion) {
      content = Text(
        resolvedLabel,
        style: context.theme.typography.body.lg,
        textAlign: TextAlign.center,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BusyIndicator(value: value, semanticsLabel: resolvedSemantics),
          const SizedBox(height: AppSpacing.md),
          Text(
            resolvedLabel,
            style: context.theme.typography.body.md,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return AbsorbPointer(
      child: ColoredBox(
        color: context.theme.colors.barrier,
        child: BlockSemantics(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: MergeSemantics(
                child: Semantics(label: resolvedSemantics, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
