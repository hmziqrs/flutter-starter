import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';

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
