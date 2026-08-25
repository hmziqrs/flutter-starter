import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/search/search_page.dart';

List<RouteBase> buildSearchRoutes() => [
  GoRoute(
    name: AppRoutes.search,
    path: AppRoutes.searchPath,
    builder: (context, state) => SearchPage(
      onBack: () => popOrGoNamed(context, AppRoutes.home),
    ),
  ),
];
