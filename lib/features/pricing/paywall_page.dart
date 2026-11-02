import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/widgets/billing_selector.dart';
import 'package:starter/features/pricing/widgets/plan_card.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';
import 'package:starter/shared/widgets/brand/app_notice.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

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
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
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
                spacing.xl,
                spacing.sm,
                spacing.xl,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FButton(
                  key: const ValueKey('paywall-skip'),
                  variant: .ghost,
                  // Ten-foot presentation needs a focusable anchor on arrival
                  // and the primary Continue is disabled until a plan is
                  // picked, so the skip takes the cold focus there; pointer
                  // surfaces stay calm (no focus ring on entry).
                  autofocus: AppPresentationPolicy.maybeOf(context)?.usesDirectionalFocus ?? false,
                  mainAxisSize: .min,
                  style: const .delta(
                    tappableStyle: .delta(
                      motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                    ),
                  ),
                  onPress: widget.onSkip,
                  // The least important action on the screen (the onboarding
                  // page's _QuietSkip recipe): muted 14 on the app type scale.
                  child: Text(
                    translations.common.skip,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.xl,
                  spacing.sm,
                  spacing.xl,
                  spacing.xl3,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: tokens.wideContentMaxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The kit's page-intro composition (page-intro.svelte
                          // at the app type scale), the same recipe home and
                          // pricing open with: title 24 w500 tracking-tight
                          // over the one muted line at the block's gap-6.
                          AppPageIntro(
                            title: translations.pricing.paywallTitle,
                            description: translations.pricing.paywallBody,
                          ),
                          SizedBox(height: spacing.lg),
                          _BenefitList(
                            benefits: [
                              translations.pricing.benefitAdaptive,
                              translations.pricing.benefitLocalized,
                              translations.pricing.benefitAccessible,
                            ],
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
                            AppNotice(
                              key: const ValueKey('paywall-unavailable'),
                              role: AppStatusRole.destructive,
                              title: translations.pricing.unavailableReason,
                            ),
                          ],
                          SizedBox(height: spacing.xl),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final gaps = spacing.lg * (columns - 1);
                              final width = (constraints.maxWidth - gaps) / columns;
                              return Wrap(
                                key: ValueKey('paywall-layout-${layoutClass.name}'),
                                spacing: spacing.lg,
                                runSpacing: spacing.lg,
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
                                        // Continue is this view's one primary
                                        // button (BRAND.md s4); plan actions
                                        // stay outline.
                                        primaryAction: false,
                                        onSelect: _isAvailable(plan)
                                            ? () => setState(() => _selectedPlanId = plan.id)
                                            : null,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: spacing.xl),
                          FButton(
                            key: const ValueKey('paywall-continue'),
                            // Ten-foot presentation focuses the primary
                            // action on arrival; pointer surfaces stay calm.
                            autofocus:
                                AppPresentationPolicy.maybeOf(context)?.usesDirectionalFocus ??
                                false,
                            onPress: _canContinue
                                ? () => widget.onContinue(_selectedPlan, _billingPeriod)
                                : null,
                            style: const .delta(
                              tappableStyle: .delta(
                                motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                              ),
                            ),
                            builder: (_, _, _, _, _, child) => Flexible(child: child!),
                            child: Text(
                              translations.pricing.paywallContinue,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: spacing.sm),
                          Text(
                            translations.pricing.staticPurchaseNotice,
                            textAlign: TextAlign.center,
                            style: context.theme.typography.body.sm,
                          ),
                          SizedBox(height: spacing.md),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: spacing.sm,
                            runSpacing: spacing.sm,
                            children: [
                              FButton(
                                key: const ValueKey('paywall-restore'),
                                variant: .ghost,
                                mainAxisSize: .min,
                                style: const .delta(
                                  tappableStyle: .delta(
                                    motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                                  ),
                                ),
                                onPress: widget.onRestore,
                                child: Text(translations.pricing.restore),
                              ),
                              FButton(
                                key: const ValueKey('paywall-terms'),
                                variant: .ghost,
                                mainAxisSize: .min,
                                style: const .delta(
                                  tappableStyle: .delta(
                                    motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                                  ),
                                ),
                                onPress: widget.onOpenTerms,
                                child: Text(translations.pricing.terms),
                              ),
                              FButton(
                                key: const ValueKey('paywall-privacy'),
                                variant: .ghost,
                                mainAxisSize: .min,
                                style: const .delta(
                                  tappableStyle: .delta(
                                    motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                                  ),
                                ),
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
    final theme = context.theme;
    final spacing = context.spacing;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The plan-card benefit recipe (a filled orange ring before each
          // item, the words 14dp muted): the same list shape the cards below
          // use, so the page carries one bullet language.
          for (final benefit in benefits)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AppRingMarker(filled: true, color: theme.colors.primary),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(fontSize: 14, color: theme.colors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
