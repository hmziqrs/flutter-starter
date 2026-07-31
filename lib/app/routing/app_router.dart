import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_guards.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/app/shell/app_shell.dart';
import 'package:starter/app/shell/cross_fading_branch_container.dart';
import 'package:starter/features/auth/auth_routes.dart';
import 'package:starter/features/dev_gallery/dev_gallery_routes.dart';
import 'package:starter/features/force_update/force_update_routes.dart';
import 'package:starter/features/home/home_routes.dart';
import 'package:starter/features/onboarding/onboarding_routes.dart';
import 'package:starter/features/pricing/pricing_routes.dart';
import 'package:starter/features/profile/profile_routes.dart';
import 'package:starter/features/search/search_routes.dart';
import 'package:starter/features/security/security_routes.dart';
import 'package:starter/features/settings/settings_routes.dart';
import 'package:starter/features/splash/splash_routes.dart';

GoRouter buildAppRouter({
  required AppConfig config,
  String initialLocation = AppRoutes.splashPath,
  bool hasCompletedOnboarding = false,
  List<NavigatorObserver> observers = const <NavigatorObserver>[],
}) {
  // hasCompletedOnboarding is a fallback seed for test harnesses that build the
  // router without a ProviderScope; appRedirect reads the live settings state.
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: crossFadingBranchContainer,
        branches: [
          StatefulShellBranch(routes: buildHomeRoutes()),
          StatefulShellBranch(routes: buildPricingRoutes()),
          StatefulShellBranch(routes: buildSettingsRoutes()),
        ],
      ),
      ...buildSplashRoutes(),
      ...buildOnboardingRoutes(),
      ...buildForceUpdateRoutes(),
      ...buildSecurityRoutes(),
      ...buildSearchRoutes(),
      ...buildAuthRoutes(),
      ...buildProfileRoutes(),
      ...buildDevGalleryRoutes(config: config),
    ],
    errorBuilder: buildRouteErrorPage,
    observers: observers,
    // C5: this remains the router's one and only redirect callback.
    redirect: (context, state) => appRedirect(
      context,
      state,
      hasCompletedOnboardingSeed: hasCompletedOnboarding,
    ),
  );
}
