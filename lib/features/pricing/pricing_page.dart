import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/widgets/billing_selector.dart';
import 'package:starter/features/pricing/widgets/plan_card.dart';
import 'package:starter/features/pricing/widgets/plan_comparison.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class PricingPage extends ConsumerStatefulWidget {
  PricingPage({
    required List<PlanViewData> plans,
    required this.onSelectPlan,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.initialBillingPeriod = BillingPeriod.monthly,
    this.initialPlanId,
    this.availability = PricingAvailability.available,
    super.key,
  }) : assert(plans.isNotEmpty, 'Pricing needs at least one plan.'),
       assert(_hasUniquePlanIds(plans), 'Plan IDs must be unique.'),
       assert(
         initialPlanId == null || plans.any((plan) => plan.id == initialPlanId),
         'The initial plan ID must identify a supplied plan.',
       ),
       plans = List.unmodifiable(plans);

  final List<PlanViewData> plans;
  final PlanSelectionCallback onSelectPlan;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final BillingPeriod initialBillingPeriod;
  final String? initialPlanId;
  final PricingAvailability availability;

  @override
  ConsumerState<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends ConsumerState<PricingPage> {
  late BillingPeriod _billingPeriod = widget.initialBillingPeriod;
  late String _selectedPlanId = widget.initialPlanId ?? _preferredPlan(widget.plans).id;

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final translations = context.t;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return ListView(
      key: const ValueKey('pricing-page'),
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl2,
        context.spacing.xl,
        context.spacing.xl3,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.wideContentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(translations.pricing.title, style: context.theme.typography.display.xl3),
                SizedBox(height: context.spacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSizes.readingContentMaxWidth),
                  child: Text(
                    translations.pricing.body,
                    style: context.theme.typography.body.lg,
                  ),
                ),
                SizedBox(height: context.spacing.xl),
                BillingSelector(
                  value: _billingPeriod,
                  monthlyLabel: translations.pricing.monthly,
                  annualLabel: translations.pricing.annual,
                  enabled: _hasAvailablePlan,
                  onChanged: (period) => setState(() => _billingPeriod = period),
                ),
                if (!_hasAvailablePlan) ...[
                  SizedBox(height: context.spacing.lg),
                  FAlert(
                    key: const ValueKey('pricing-unavailable'),
                    variant: .destructive,
                    title: Text(translations.pricing.unavailableReason),
                  ),
                ],
                SizedBox(height: context.spacing.xl),
                _PlanGrid(
                  key: ValueKey('pricing-layout-${layoutClass.name}'),
                  layoutClass: layoutClass,
                  children: [
                    for (final plan in widget.plans)
                      PlanCard(
                        plan: plan,
                        formattedPrice: plan.formattedPrice(
                          _billingPeriod,
                          locale: locale,
                        ),
                        periodLabel: _billingPeriod == BillingPeriod.monthly
                            ? translations.pricing.periodMonth
                            : translations.pricing.periodYear,
                        actionLabel: translations.pricing.choosePlan(plan: plan.name),
                        recommendedLabel: translations.pricing.recommended,
                        currentLabel: translations.pricing.current,
                        unavailableLabel: _isAvailable(plan)
                            ? null
                            : translations.pricing.unavailable,
                        selected: plan.id == _selectedPlanId,
                        onSelect: _isAvailable(plan)
                            ? () {
                                setState(() => _selectedPlanId = plan.id);
                                widget.onSelectPlan(plan, _billingPeriod);
                              }
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl2),
                PlanComparison(
                  title: translations.pricing.comparisonTitle,
                  plans: widget.plans,
                ),
                const SizedBox(height: AppSpacing.xl),
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          translations.pricing.faqTitle,
                          style: context.theme.typography.display.lg,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          translations.pricing.faqQuestion,
                          style: context.theme.typography.body.lg,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(translations.pricing.faqAnswer),
                        const SizedBox(height: AppSpacing.lg),
                        Text(translations.pricing.staticPurchaseNotice),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            FButton(
                              key: const ValueKey('pricing-terms'),
                              variant: .ghost,
                              mainAxisSize: .min,
                              onPress: widget.onOpenTerms,
                              child: Text(translations.pricing.terms),
                            ),
                            FButton(
                              key: const ValueKey('pricing-privacy'),
                              variant: .ghost,
                              mainAxisSize: .min,
                              onPress: widget.onOpenPrivacy,
                              child: Text(translations.pricing.privacy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isAvailable(PlanViewData plan) {
    return widget.availability == PricingAvailability.available &&
        plan.availability == PricingAvailability.available;
  }

  bool get _hasAvailablePlan => widget.plans.any(_isAvailable);
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.layoutClass, required this.children, super.key});

  final AppLayoutClass layoutClass;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = switch (layoutClass) {
      AppLayoutClass.compact => 1,
      AppLayoutClass.medium => 2,
      AppLayoutClass.expanded => 3,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (AppSpacing.lg * (columns - 1));
        final cardWidth = availableWidth / columns;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [
            for (final child in children) SizedBox(width: cardWidth, child: child),
          ],
        );
      },
    );
  }
}

bool _hasUniquePlanIds(List<PlanViewData> plans) {
  return plans.map((plan) => plan.id).toSet().length == plans.length;
}

PlanViewData _preferredPlan(List<PlanViewData> plans) {
  final available = plans.where(
    (plan) => plan.availability == PricingAvailability.available,
  );
  return available.where((plan) => plan.isRecommended).firstOrNull ??
      available.firstOrNull ??
      plans.where((plan) => plan.isRecommended).firstOrNull ??
      plans.first;
}
