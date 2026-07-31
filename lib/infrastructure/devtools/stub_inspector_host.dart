import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

/// Production no-op; skips the inspector package (flutter/flutter#188060 AOT crash).
final class StubInspectorHost implements InspectorHost {
  const StubInspectorHost();

  @override
  Widget wrap(Widget child) => child;

  @override
  void attachInterceptor(Dio dio) {}

  @override
  List<NavigatorObserver> get navigatorObservers => const <NavigatorObserver>[];

  @override
  bool get enabled => false;
}
