import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.formattedPrice,
    required this.periodLabel,
    required this.actionLabel,
    required this.recommendedLabel,
    required this.currentLabel,
    required this.selected,
    required this.onSelect,
    this.unavailableLabel,
    super.key,
  });

  final PlanViewData plan;
  final String formattedPrice;
  final String periodLabel;
  final String actionLabel;
  final String recommendedLabel;
  final String currentLabel;
  final bool selected;
  final VoidCallback? onSelect;
  final String? unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? context.theme.colors.primary : context.theme.colors.border;
    return Semantics(
      selected: selected,
      enabled: onSelect != null,
      child: AppCard(
        key: ValueKey('plan-card-${plan.id}'),
        padding: EdgeInsets.all(context.spacing.xl),
        style: .delta(
          decoration: .shapeDelta(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: accent, width: selected ? 2 : 1),
              borderRadius: context.theme.style.borderRadius.lg,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(plan.name, style: context.theme.typography.display.xl),
                if (plan.isRecommended) FBadge(child: Text(recommendedLabel)),
                if (plan.isCurrent) FBadge(variant: .outline, child: Text(currentLabel)),
                if (unavailableLabel case final label?)
                  FBadge(variant: .destructive, child: Text(label)),
              ],
            ),
            SizedBox(height: context.spacing.sm),
            Text(plan.description, style: context.theme.typography.body.sm),
            SizedBox(height: context.spacing.xl),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: context.spacing.sm,
              children: [
                Text(formattedPrice, style: context.theme.typography.display.xl2),
                Padding(
                  padding: EdgeInsets.only(bottom: context.spacing.xs),
                  child: Text(periodLabel, style: context.theme.typography.body.sm),
                ),
              ],
            ),
            SizedBox(height: context.spacing.lg),
            for (final benefit in plan.benefits) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(FLucideIcons.check, size: 18),
                  ),
                  SizedBox(width: context.spacing.sm),
                  Expanded(child: Text(benefit)),
                ],
              ),
              SizedBox(height: context.spacing.sm),
            ],
            SizedBox(height: context.spacing.md),
            FButton(
              key: ValueKey('select-plan-${plan.id}'),
              variant: selected ? .primary : .outline,
              onPress: onSelect,
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                actionLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
