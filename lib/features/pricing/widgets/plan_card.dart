import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
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
    final spacing = context.spacing;
    return Semantics(
      selected: selected,
      enabled: onSelect != null,
      child: AppCard(
        key: ValueKey('plan-card-${plan.id}'),
        padding: EdgeInsets.all(spacing.xl),
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
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(plan.name, style: context.theme.typography.display.xl),
                if (plan.isRecommended) FBadge(child: Text(recommendedLabel)),
                if (plan.isCurrent) FBadge(variant: .outline, child: Text(currentLabel)),
                if (unavailableLabel case final label?)
                  FBadge(variant: .destructive, child: Text(label)),
              ],
            ),
            SizedBox(height: spacing.sm),
            Text(plan.description, style: context.theme.typography.body.sm),
            SizedBox(height: spacing.xl),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: spacing.sm,
              children: [
                Text(formattedPrice, style: context.theme.typography.display.xl2),
                Padding(
                  padding: EdgeInsets.only(bottom: spacing.xs),
                  child: Text(periodLabel, style: context.theme.typography.body.sm),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            for (final benefit in plan.benefits) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: context.appUnit.snap(2)),
                    child: const Icon(FLucideIcons.check, size: 18),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(child: Text(benefit)),
                ],
              ),
              SizedBox(height: spacing.sm),
            ],
            SizedBox(height: spacing.md),
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
