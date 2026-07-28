import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// `GoRouter` `observers:` entry that emits a [ScreenView] on every route
/// change — zero per-page edits (C4: analytics plugs into an existing seam).
///
/// Attached via `GoRouter(observers: [AnalyticsRouteObserver(client: ...)])` in
/// `buildAppRouter`. The observer reads only `route.settings.name` (a typed
/// `String?`) — never raw route args. `go_router` resolves that to
/// `state.name ?? state.path` when it builds each page, so a named route yields
/// its `GoRoute.name` and an unnamed route yields its path. Anonymous routes
/// with no name and no path are skipped so the client never receives garbage.
///
/// Emits on [didPush] (forward navigation), [didReplace] (a route swapped in),
/// and [didPop] (the previous route becomes visible again) — every transition
/// where a distinct screen is shown. The [AnalyticsClient.track] call is
/// fire-and-forget ([unawaited]); the client swallows backend failures and the
/// observer itself never throws, so navigation is never gated on analytics
/// (motion/navigation rule).
final class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver({required this.client});

  final AnalyticsClient client;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _emit(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _emit(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _emit(previousRoute);

  void _emit(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    // Fire-and-forget: the client never throws and navigation must not wait on
    // analytics. [unawaited] documents the intent.
    unawaited(client.track(ScreenView(routeName: name)));
  }
}
