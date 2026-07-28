import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';

/// A modal busy overlay that blocks duplicate submits while [isBusy] is true.
///
/// Wraps [child] in a [Stack]; when [isBusy] mounts a translucent scrim plus a
/// centered [BusyIndicator] that absorbs pointer events, so the wrapped submit
/// action cannot be triggered again. The overlay is purely visual — it never
/// gates [child]'s callbacks, so the action still completes even when the
/// spinner is replaced by a static label under reduce-motion. Navigation is
/// therefore never gated on the indicator (audit checklist #5).
///
/// Pass a [value] of `null` for an indeterminate spinner or a fraction in
/// `0.0..1.0` for a determinate bar. The visible [label] defaults to the
/// localized `common.saving`; an explicit [semanticsLabel] overrides the
/// spinner's accessibility label (defaulting to [label]).
class BusyOverlay extends StatelessWidget {
  /// Creates a [BusyOverlay].
  const BusyOverlay({
    required this.isBusy,
    required this.child,
    this.label,
    this.semanticsLabel,
    this.value,
    super.key,
  });

  /// Whether the modal scrim is mounted over [child].
  final bool isBusy;

  /// The content covered by the scrim while [isBusy] is true.
  final Widget child;

  /// Visible caption shown beneath the spinner and as the static reduce-motion
  /// label. Defaults to the localized `common.saving`.
  final String? label;

  /// Accessibility label forwarded to the spinner. Defaults to [label] (or
  /// `common.saving` when both are null).
  final String? semanticsLabel;

  /// Determinate progress fraction (`0.0..1.0`); `null` is indeterminate.
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
              // Stable identity for widget/integration tests and gallery previews.
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
      // Reduce-motion: a static localized label replaces the animated spinner.
      // The underlying action is unaffected — the overlay never gates callbacks.
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

    // AbsorbPointer blocks the duplicate submit; BlockSemantics hides the
    // underlying form from assistive technology while the scrim is mounted.
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
