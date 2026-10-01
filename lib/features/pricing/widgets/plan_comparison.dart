import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

class PlanComparison extends StatelessWidget {
  const PlanComparison({required this.title, required this.plans, super.key});

  final String title;
  final List<PlanViewData> plans;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('plan-comparison'),
      padding: EdgeInsets.all(context.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.theme.typography.display.lg),
          SizedBox(height: context.spacing.lg),
          Wrap(
            spacing: context.spacing.lg,
            runSpacing: context.spacing.lg,
            children: [
              for (final plan in plans)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: context.appUnit.un(180) * context.presentationTokens.spacingScale,
                    maxWidth: context.appUnit.un(320) * context.presentationTokens.spacingScale,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: context.theme.typography.body.lg),
                      SizedBox(height: context.spacing.sm),
                      for (final benefit in plan.benefits)
                        Padding(
                          padding: EdgeInsets.only(bottom: context.spacing.xs),
                          child: Text('• $benefit'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
