import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/pricing_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/widgets/feedback/legal_dialog_callbacks.dart';

List<RouteBase> buildPricingRoutes() => [
  GoRoute(
    name: AppRoutes.pricing,
    path: AppRoutes.pricingPath,
    builder: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.pricing.terms,
        privacyTitle: context.t.pricing.privacy,
      );
      // Deferred local plan load (backend-free by the skeleton contract): the
      // plans compose after the first rendered frame so the pricing grid has a
      // real pending state for the skeleton bones.
      final translations = context.t;
      return PricingPage(
        plans: PricingFixtures.standard(translations),
        plansLoader: () async {
          await SchedulerBinding.instance.endOfFrame;
          return PricingFixtures.standard(translations);
        },
        onSelectPlan: (plan, _) => showAppInformationDialog(
          context,
          title: context.t.pricing.choosePlan(plan: plan.name),
          body: context.t.pricing.staticPurchaseNotice,
        ),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
      );
    },
  ),
];
