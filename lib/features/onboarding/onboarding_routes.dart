import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/features/pricing/paywall_page.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/i18n/translations.g.dart';

List<RouteBase> buildOnboardingRoutes() => [
  GoRoute(
    name: AppRoutes.onboarding,
    path: AppRoutes.onboardingPath,
    builder: (context, state) => OnboardingPage(
      onSkip: () => _completeOnboardingAndGoHome(context),
      onOpenPaywall: () => context.goNamed(AppRoutes.onboardingPaywall),
    ),
  ),
  GoRoute(
    name: AppRoutes.onboardingPaywall,
    path: AppRoutes.onboardingPaywallPath,
    builder: (context, state) => PaywallPage(
      plans: PricingFixtures.standard(context.t),
      onSkip: () => _completeOnboardingAndGoHome(context),
      onContinue: (_, _) => _completeOnboardingAndGoHome(context),
      onRestore: () => showAppInformationDialog(
        context,
        title: context.t.pricing.restore,
        body: context.t.pricing.restoreUnavailable,
      ),
      onOpenTerms: () => showAppInformationDialog(
        context,
        title: context.t.pricing.terms,
      ),
      onOpenPrivacy: () => showAppInformationDialog(
        context,
        title: context.t.pricing.privacy,
      ),
    ),
  ),
];

void _completeOnboardingAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(settingsControllerProvider.notifier).markOnboardingComplete());
  context.goNamed(AppRoutes.home);
}
