import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
    return Semantics(
      container: true,
      child: Wrap(
        key: const ValueKey('billing-selector'),
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          FButton(
            key: const ValueKey('billing-monthly'),
            variant: value == BillingPeriod.monthly ? .primary : .outline,
            selected: value == BillingPeriod.monthly,
            mainAxisSize: .min,
            onPress: enabled ? () => onChanged(BillingPeriod.monthly) : null,
            child: Text(monthlyLabel),
          ),
          FButton(
            key: const ValueKey('billing-annual'),
            variant: value == BillingPeriod.annual ? .primary : .outline,
            selected: value == BillingPeriod.annual,
            mainAxisSize: .min,
            onPress: enabled ? () => onChanged(BillingPeriod.annual) : null,
            child: Text(annualLabel),
          ),
        ],
      ),
    );
  }
}
