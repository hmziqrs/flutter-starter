import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/home/home_page.dart';
import 'package:starter/features/home/home_view_data.dart';

List<RouteBase> buildHomeRoutes() => [
  GoRoute(
    name: AppRoutes.home,
    path: AppRoutes.homePath,
    builder: (context, state) => HomePage(
      viewData: HomeViewData.defaults(),
      onOpenProfile: () => context.pushNamed(AppRoutes.updateProfile),
      onOpenPricing: () => goAppTab(context, 1),
      onOpenSettings: () => goAppTab(context, 2),
      onOpenLogin: () => context.pushNamed(AppRoutes.login),
    ),
  ),
];
