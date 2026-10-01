import 'dart:math' as math;

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
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';

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
       assert(hasUniquePlanIds(plans), 'Plan IDs must be unique.'),
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
  late String _selectedPlanId = widget.initialPlanId ?? preferredPlan(widget.plans).id;

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final translations = context.t;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final spacing = context.spacing;
    final tokens = context.presentationTokens;

    return SafeArea(
      bottom: false,
      child: ReadingContentScrollFrame(
        key: const ValueKey('pricing-page'),
        maxWidth: tokens.wideContentMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(translations.pricing.title, style: context.theme.typography.display.xl3),
            SizedBox(height: spacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.readingContentMaxWidth,
              ),
              child: Text(
                translations.pricing.body,
                style: context.theme.typography.body.lg,
              ),
            ),
            SizedBox(height: spacing.xl),
            BillingSelector(
              value: _billingPeriod,
              monthlyLabel: translations.pricing.monthly,
              annualLabel: translations.pricing.annual,
              enabled: _hasAvailablePlan,
              onChanged: (period) => setState(() => _billingPeriod = period),
            ),
            if (!_hasAvailablePlan) ...[
              SizedBox(height: spacing.lg),
              FAlert(
                key: const ValueKey('pricing-unavailable'),
                variant: .destructive,
                title: Text(translations.pricing.unavailableReason),
              ),
            ],
            SizedBox(height: spacing.xl),
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
                    unavailableLabel: _isAvailable(plan) ? null : translations.pricing.unavailable,
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
            SizedBox(height: spacing.xl2),
            PlanComparison(
              title: translations.pricing.comparisonTitle,
              plans: widget.plans,
            ),
            SizedBox(height: spacing.xl),
            FCard(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations.pricing.faqTitle,
                      style: context.theme.typography.display.lg,
                    ),
                    SizedBox(height: spacing.md),
                    Text(
                      translations.pricing.faqQuestion,
                      style: context.theme.typography.body.lg,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(translations.pricing.faqAnswer),
                    SizedBox(height: spacing.lg),
                    Text(translations.pricing.staticPurchaseNotice),
                    SizedBox(height: spacing.lg),
                    Wrap(
                      spacing: spacing.sm,
                      runSpacing: spacing.sm,
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
        final spacing = context.spacing;
        final tokens = context.presentationTokens;
        final gap = spacing.lg;
        final minimumCardExtent = tokens.focusTargetMinSize * 5;
        final fittingColumns = math.max(
          1,
          ((constraints.maxWidth + gap) / (minimumCardExtent + gap)).floor(),
        );
        final resolvedColumns = math.min(columns, fittingColumns);
        final availableWidth = constraints.maxWidth - (gap * (resolvedColumns - 1));
        final cardWidth = availableWidth / resolvedColumns;
        return FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final child in children) SizedBox(width: cardWidth, child: child),
            ],
          ),
        );
      },
    );
  }
}
