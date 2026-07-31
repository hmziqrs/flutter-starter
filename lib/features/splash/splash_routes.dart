import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/splash/splash_page.dart';

List<RouteBase> buildSplashRoutes() => [
  GoRoute(
    name: AppRoutes.splash,
    path: AppRoutes.splashPath,
    builder: (context, state) => SplashPage(
      // Goes to home; the onboarding redirect then sends fresh installs to
      // /onboarding, and the HARD update-blocker redirect wins over both.
      onComplete: (_) => context.goNamed(AppRoutes.home),
    ),
  ),
];
