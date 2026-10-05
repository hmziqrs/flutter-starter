import 'dart:async' show unawaited;
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
import 'package:starter/shared/widgets/feedback/app_toast.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';
import 'package:starter/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

class PricingPage extends ConsumerStatefulWidget {
  PricingPage({
    required List<PlanViewData> plans,
    required this.onSelectPlan,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.plansLoader,
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

  /// Deferred plan source. Backend-free by contract
  /// (`plans/feature_roadmap/features/skeleton.md`): the loader composes the
  /// plans locally (no network) and the page mirrors skeleton bones over the
  /// plan grid while it pends, then transitions to the loaded cards. Null
  /// (paywall and direct constructions) renders [plans] synchronously.
  final Future<List<PlanViewData>> Function()? plansLoader;

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
  List<PlanViewData>? _loadedPlans;
  Object? _plansError;
  Future<List<PlanViewData>>? _plansFuture;
  bool _userSelectedPlan = false;
  int _loadEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_beginRefresh() ?? Future<void>.value());
  }

  /// The plans the page renders: the loaded set once the deferred source
  /// resolves, the injected [PricingPage.plans] before that (and always for
  /// direct constructions without a loader).
  List<PlanViewData> get _effectivePlans => _loadedPlans ?? widget.plans;

  bool get _showingSkeleton => _plansFuture != null && _loadedPlans == null && _plansError == null;

  void _onPlansReady(int epoch, List<PlanViewData> plans) {
    if (epoch != _loadEpoch || !mounted) return;
    setState(() {
      _loadedPlans = plans;
      _plansError = null;
      // A refresh keeps the user's selection; the preferred plan only takes
      // over before any selection exists or when the selected plan vanished.
      final selectionStillValid = plans.any((plan) => plan.id == _selectedPlanId);
      if (!_userSelectedPlan || !selectionStillValid) {
        _selectedPlanId = preferredPlan(plans).id;
        _userSelectedPlan = false;
      }
    });
  }

  void _onPlansFailed(int epoch, Object error) {
    if (epoch != _loadEpoch || !mounted) return;
    setState(() {
      // A failed refresh keeps the already-loaded content on screen; the
      // error view only applies when nothing has loaded yet.
      if (_loadedPlans == null) {
        _plansError = error;
      }
    });
  }

  /// Backend-free by contract (`plans/feature_roadmap/features/pull-refresh.md`):
  /// recompose the local plans, then report the honest `common.notConnected`
  /// outcome — never faked success. The loader failure path is handled by the
  /// epoch-guarded listener; the await only holds the indicator open, so its
  /// rethrow is swallowed rather than escaping as an unhandled zone error.
  Future<void> _refreshPlans(BuildContext context) async {
    final loader = widget.plansLoader;
    if (loader != null) {
      final future = _beginRefresh();
      if (future != null) {
        try {
          await future;
        } on Object {
          // Handled by the listener; the honest toast still surfaces below.
        }
      }
    }
    if (!context.mounted) return;
    AppToast.show(
      context,
      severity: ToastSeverity.warning,
      message: context.t.common.notConnected,
    );
  }

  /// Starts a loader run under a fresh epoch: only the most recently started
  /// load may mutate the page state, so a refresh that overtakes a pending
  /// initial load (or vice versa) cannot clobber it. The listeners attach
  /// before any mounted check so a disposal-window completion is still
  /// swallowed by the epoch guard instead of escaping as an unhandled error.
  Future<List<PlanViewData>>? _beginRefresh() {
    final loader = widget.plansLoader;
    if (loader == null) return null;
    final epoch = ++_loadEpoch;
    final future = loader();
    unawaited(
      future.then(
        (plans) => _onPlansReady(epoch, plans),
        onError: (Object error) => _onPlansFailed(epoch, error),
      ),
    );
    if (!mounted) return future;
    if (_plansFuture == null && _plansError == null) {
      // initState: build has not run yet, so plain assignment is correct.
      _plansFuture = future;
    } else {
      setState(() {
        _plansFuture = future;
        _plansError = null;
      });
    }
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final translations = context.t;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    final plans = _effectivePlans;

    return SafeArea(
      bottom: false,
      child: AppRefreshIndicator(
        onRefresh: () => _refreshPlans(context),
        child: ReadingContentScrollFrame(
          key: const ValueKey('pricing-page'),
          maxWidth: tokens.wideContentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(translations.pricing.title, style: context.theme.typography.display.xl3),
              SizedBox(height: spacing.md),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tokens.readingContentMaxWidth),
                child: Text(translations.pricing.body, style: context.theme.typography.body.lg),
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
              if (_showingSkeleton)
                SkeletonView(
                  key: const ValueKey('pricing-plans-skeleton'),
                  child: _PlanGrid(
                    layoutClass: layoutClass,
                    children: [
                      for (var index = 0; index < _skeletonBoneCount; index++)
                        SizedBox(
                          key: ValueKey('pricing-skeleton-$index'),
                          height: tokens.focusTargetMinSize * 5,
                          child: const SkeletonTile(),
                        ),
                    ],
                  ),
                )
              else if (_plansError != null)
                ErrorStateView(
                  key: const ValueKey('pricing-plans-error'),
                  title: translations.states.errorTitle,
                  body: translations.states.errorBody,
                )
              else
                _PlanGrid(
                  key: ValueKey('pricing-layout-${layoutClass.name}'),
                  layoutClass: layoutClass,
                  children: _planCards(translations, locale, plans),
                ),
              SizedBox(height: spacing.xl2),
              if (!_showingSkeleton && _plansError == null)
                PlanComparison(title: translations.pricing.comparisonTitle, plans: plans),
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
      ),
    );
  }

  static const _skeletonBoneCount = 3;

  List<Widget> _planCards(Translations translations, String locale, List<PlanViewData> plans) {
    return [
      for (final plan in plans)
        PlanCard(
          plan: plan,
          formattedPrice: plan.formattedPrice(_billingPeriod, locale: locale),
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
                  setState(() {
                    _selectedPlanId = plan.id;
                    _userSelectedPlan = true;
                  });
                  widget.onSelectPlan(plan, _billingPeriod);
                }
              : null,
        ),
    ];
  }

  bool _isAvailable(PlanViewData plan) {
    return widget.availability == PricingAvailability.available &&
        plan.availability == PricingAvailability.available;
  }

  bool get _hasAvailablePlan => _effectivePlans.any(_isAvailable);
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
