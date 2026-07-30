import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

/// `GoRouter` `observers:` entry that emits a [ScreenView] on every route
/// change, with zero per-page edits. Reads only `route.settings.name`
/// (resolved by `go_router` to `state.name ?? state.path`); anonymous routes
/// with neither are skipped. Emits on [didPush], [didReplace], and [didPop].
///
/// [AnalyticsClient.track] is fire-and-forget so navigation is never gated
/// on analytics.
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
    unawaited(client.track(ScreenView(routeName: name)));
  }
}
