import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/search/search_page.dart';

List<RouteBase> buildSearchRoutes() => [
  GoRoute(
    name: AppRoutes.search,
    path: AppRoutes.searchPath,
    // Top-level, outside the StatefulShellRoute; not a shell-tab or
    // auth-required destination so it falls through the redirect untouched.
    builder: (context, state) => SearchPage(
      onBack: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          context.goNamed(AppRoutes.home);
        }
      },
    ),
  ),
];
