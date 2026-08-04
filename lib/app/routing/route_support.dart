import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_error_page.dart';

// Re-exported so existing route modules that import this helper (e.g. the
// profile routes) keep compiling after the dialog moved to shared/feedback.
export 'package:starter/shared/widgets/feedback/app_information_dialog.dart';

void goAppTab(BuildContext context, int index) {
  final shell = StatefulNavigationShell.of(context);
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

/// Pops the current route when there is somewhere to return to, otherwise falls
/// back to a [GoRouter.goNamed] navigation.
///
/// Pass [result] to deliver a value to the previous route's `push`/`pushNamed`
/// caller when popping. [queryParameters] only apply to the fallback navigation
/// and are ignored on the pop path, mirroring the manual pattern this unifies.
void popOrGoNamed(
  BuildContext context,
  String name, {
  Object? result,
  Map<String, String> queryParameters = const <String, String>{},
}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop(result);
    return;
  }
  context.goNamed(name, queryParameters: queryParameters);
}

RouteErrorPage buildRouteErrorPage(
  BuildContext context,
  GoRouterState state, {
  String? message,
}) {
  final router = GoRouter.of(context);
  return RouteErrorPage(
    location: state.uri.toString(),
    message: message,
    onHome: () => context.goNamed(AppRoutes.home),
    onBack: () {
      if (router.canPop()) {
        router.pop();
      }
    },
  );
}
