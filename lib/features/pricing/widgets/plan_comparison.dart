import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class PlanComparison extends StatelessWidget {
  const PlanComparison({required this.title, required this.plans, super.key});

  final String title;
  final List<PlanViewData> plans;

  @override
  Widget build(BuildContext context) {
    return FCard(
      key: const ValueKey('plan-comparison'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.theme.typography.display.lg),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                for (final plan in plans)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: context.theme.typography.body.lg),
                        const SizedBox(height: AppSpacing.sm),
                        for (final benefit in plan.benefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text('• $benefit'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
