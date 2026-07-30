import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/widgets/billing_selector.dart';
import 'package:starter/features/pricing/widgets/plan_card.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class PaywallPage extends StatefulWidget {
  PaywallPage({
    required List<PlanViewData> plans,
    required this.onSkip,
    required this.onContinue,
    required this.onRestore,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.initialBillingPeriod = BillingPeriod.monthly,
    this.initialPlanId,
    this.availability = PricingAvailability.available,
    super.key,
  }) : assert(plans.isNotEmpty, 'The paywall needs at least one plan.'),
       assert(hasUniquePlanIds(plans), 'Plan IDs must be unique.'),
       assert(
         initialPlanId == null || plans.any((plan) => plan.id == initialPlanId),
         'The initial plan ID must identify a supplied plan.',
       ),
       plans = List.unmodifiable(plans);

  final List<PlanViewData> plans;
  final VoidCallback onSkip;
  final PlanSelectionCallback onContinue;
  final VoidCallback onRestore;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final BillingPeriod initialBillingPeriod;
  final String? initialPlanId;
  final PricingAvailability availability;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  late BillingPeriod _billingPeriod = widget.initialBillingPeriod;
  late String _selectedPlanId = widget.initialPlanId ?? preferredPlan(widget.plans).id;

  PlanViewData get _selectedPlan {
    return widget.plans.firstWhere((plan) => plan.id == _selectedPlanId);
  }

  bool get _canContinue {
    return widget.availability == PricingAvailability.available &&
        _selectedPlan.availability == PricingAvailability.available;
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => Consumer(
        builder: (context, ref, _) {
          return _buildContent(context, ref.watch(appLayoutClassProvider));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLayoutClass layoutClass) {
    final translations = context.t;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final columns = switch (layoutClass) {
      AppLayoutClass.compact => 1,
      AppLayoutClass.medium => 2,
      AppLayoutClass.expanded => 3,
    };

    return FScaffold(
      childPad: false,
      child: SafeArea(
        child: Column(
          key: const ValueKey('paywall-page'),
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                context.spacing.xl,
                context.spacing.sm,
                context.spacing.xl,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FButton(
                  key: const ValueKey('paywall-skip'),
                  variant: .ghost,
                  autofocus: true,
                  mainAxisSize: .min,
                  onPress: widget.onSkip,
                  child: Text(translations.common.skip),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  context.spacing.xl,
                  context.spacing.sm,
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
                          Text(
                            translations.pricing.paywallTitle,
                            style: context.theme.typography.display.xl3,
                          ),
                          SizedBox(height: context.spacing.md),
                          Text(
                            translations.pricing.paywallBody,
                            style: context.theme.typography.body.lg,
                          ),
                          SizedBox(height: context.spacing.lg),
                          _BenefitList(
                            benefits: [
                              translations.pricing.benefitAdaptive,
                              translations.pricing.benefitLocalized,
                              translations.pricing.benefitAccessible,
                            ],
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
                            const SizedBox(height: AppSpacing.lg),
                            FAlert(
                              key: const ValueKey('paywall-unavailable'),
                              variant: .destructive,
                              title: Text(translations.pricing.unavailableReason),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final gaps = AppSpacing.lg * (columns - 1);
                              final width = (constraints.maxWidth - gaps) / columns;
                              return Wrap(
                                key: ValueKey('paywall-layout-${layoutClass.name}'),
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.lg,
                                children: [
                                  for (final plan in widget.plans)
                                    SizedBox(
                                      width: width,
                                      child: PlanCard(
                                        plan: plan,
                                        formattedPrice: plan.formattedPrice(
                                          _billingPeriod,
                                          locale: locale,
                                        ),
                                        periodLabel: _billingPeriod == BillingPeriod.monthly
                                            ? translations.pricing.periodMonth
                                            : translations.pricing.periodYear,
                                        actionLabel: translations.pricing.choosePlan(
                                          plan: plan.name,
                                        ),
                                        recommendedLabel: translations.pricing.recommended,
                                        currentLabel: translations.pricing.current,
                                        unavailableLabel: _isAvailable(plan)
                                            ? null
                                            : translations.pricing.unavailable,
                                        selected: plan.id == _selectedPlanId,
                                        onSelect: _isAvailable(plan)
                                            ? () => setState(() => _selectedPlanId = plan.id)
                                            : null,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FButton(
                            key: const ValueKey('paywall-continue'),
                            onPress: _canContinue
                                ? () => widget.onContinue(_selectedPlan, _billingPeriod)
                                : null,
                            builder: (_, _, _, _, _, child) => Flexible(child: child!),
                            child: Text(
                              translations.pricing.paywallContinue,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            translations.pricing.staticPurchaseNotice,
                            textAlign: TextAlign.center,
                            style: context.theme.typography.body.sm,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              FButton(
                                key: const ValueKey('paywall-restore'),
                                variant: .ghost,
                                mainAxisSize: .min,
                                onPress: widget.onRestore,
                                child: Text(translations.pricing.restore),
                              ),
                              FButton(
                                key: const ValueKey('paywall-terms'),
                                variant: .ghost,
                                mainAxisSize: .min,
                                onPress: widget.onOpenTerms,
                                child: Text(translations.pricing.terms),
                              ),
                              FButton(
                                key: const ValueKey('paywall-privacy'),
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

class _BenefitList extends StatelessWidget {
  const _BenefitList({required this.benefits});

  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(FLucideIcons.circleCheck, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
