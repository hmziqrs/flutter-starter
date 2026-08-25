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
      return PricingPage(
        plans: PricingFixtures.standard(context.t),
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
