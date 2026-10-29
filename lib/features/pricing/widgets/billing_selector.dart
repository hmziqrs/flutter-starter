import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// The brand Segmented control (BRAND.md s8 Switches): a thin outline around
/// the options; the picked one gets a soft primary fill (10% light, 20%
/// dark) with primary text. Feedback is color only; nothing moves.
class BillingSelector extends StatelessWidget {
  const BillingSelector({
    required this.value,
    required this.monthlyLabel,
    required this.annualLabel,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final BillingPeriod value;
  final String monthlyLabel;
  final String annualLabel;
  final ValueChanged<BillingPeriod> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      container: true,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Container(
          key: const ValueKey('billing-selector'),
          padding: EdgeInsets.all(context.spacing.xs),
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: colors.border,
                width: context.theme.style.borderWidth,
              ),
              borderRadius: context.theme.style.borderRadius.md,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Segment(
                buttonKey: const ValueKey('billing-monthly'),
                label: monthlyLabel,
                selected: value == BillingPeriod.monthly,
                enabled: enabled,
                onPress: () => onChanged(BillingPeriod.monthly),
              ),
              _Segment(
                buttonKey: const ValueKey('billing-annual'),
                label: annualLabel,
                selected: value == BillingPeriod.annual,
                enabled: enabled,
                onPress: () => onChanged(BillingPeriod.annual),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPress,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final softFillOpacity = colors.brightness == Brightness.dark ? 0.2 : 0.1;
    return FButton(
      key: buttonKey,
      variant: .ghost,
      selected: selected,
      mainAxisSize: .min,
      // The picked option is the soft primary pill; unpicked stays quiet and
      // tints to the muted surface on hover (color only).
      style: selected
          ? .delta(
              decoration: .delta([
                .base(
                  DecorationDelta.shapeDelta(
                    color: colors.primary.withValues(alpha: softFillOpacity),
                  ),
                ),
              ]),
              contentStyle: .delta(
                textStyle: .delta([.base(.delta(color: colors.primary))]),
              ),
              tappableStyle: const .delta(
                motion: .delta(bounceTween: FTappableMotion.noBounceTween),
              ),
            )
          : const .delta(
              tappableStyle: .delta(motion: .delta(bounceTween: FTappableMotion.noBounceTween)),
            ),
      onPress: enabled ? onPress : null,
      child: Text(label),
    );
  }
}
