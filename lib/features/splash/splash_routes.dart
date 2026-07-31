import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/splash/splash_page.dart';

List<RouteBase> buildSplashRoutes() => [
  GoRoute(
    name: AppRoutes.splash,
    path: AppRoutes.splashPath,
    builder: (context, state) => SplashPage(
      onComplete: (_) => context.goNamed(AppRoutes.home),
    ),
  ),
];
