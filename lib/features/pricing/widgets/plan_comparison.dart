import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';
import 'package:starter/shared/widgets/lists/equal_height_row.dart';

class PlanComparison extends StatelessWidget {
  const PlanComparison({required this.title, required this.plans, super.key});

  final String title;
  final List<PlanViewData> plans;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    return AppCard(
      key: const ValueKey('plan-comparison'),
      padding: EdgeInsets.all(spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section titles run 16 w500 (APP-BLOCKS).
          Text(title, style: context.theme.typography.display.sm),
          SizedBox(height: spacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = [
                for (final plan in plans)
                  _PlanColumn(key: ValueKey('plan-comparison-${plan.id}'), plan: plan),
              ];
              final minColumn = context.appUnit.un(180) * tokens.spacingScale;
              final fits =
                  constraints.maxWidth >=
                  columns.length * minColumn + (columns.length - 1) * spacing.lg;
              if (!fits) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns.length; i++) ...[
                      if (i > 0) SizedBox(height: spacing.lg),
                      columns[i],
                    ],
                  ],
                );
              }
              return EqualHeightRow(
                children: [
                  for (var i = 0; i < columns.length; i++) ...[
                    if (i > 0) SizedBox(width: spacing.lg),
                    Expanded(child: columns[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// One plan's column. The plan that matters (the recommended one) gets the
/// accent-column treatment: a soft primary wash with its heading in
/// text-primary (BRAND.md s8 Tables).
class _PlanColumn extends StatelessWidget {
  const _PlanColumn({required this.plan, super.key});

  final PlanViewData plan;

  @override
  Widget build(BuildContext context) {
    final accent = plan.isRecommended;
    final colors = context.theme.colors;
    final spacing = context.spacing;
    return Container(
      padding: accent ? EdgeInsets.all(spacing.md) : EdgeInsets.zero,
      decoration: accent
          ? ShapeDecoration(
              // The accent column: a soft primary wash at ~7% (BRAND.md s8).
              color: colors.primary.withValues(alpha: 0.07),
              shape: RoundedSuperellipseBorder(
                borderRadius: context.theme.style.borderRadius.md,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column headings are titles: w500 (BRAND.md s8 titles are
          // font-medium); the accent column's heading is text-primary.
          Text(
            plan.name,
            style: context.theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.w500,
              color: accent ? colors.primary : null,
            ),
          ),
          SizedBox(height: spacing.sm),
          for (final benefit in plan.benefits)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: context.appUnit.snap(5)),
                    // The brand marker: a hollow ring, never a solid dot
                    // (BRAND.md s7 Marker). The accent column carries it in
                    // primary; the other columns keep it quiet.
                    child: AppRingMarker(
                      color: accent ? colors.primary : colors.mutedForeground,
                      size: 8,
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(child: Text(benefit)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
