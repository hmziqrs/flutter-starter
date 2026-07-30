import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

/// No-op [InspectorHost] used by the production entrypoint. Deliberately does
/// not import `package:dio_request_inspector`, avoiding the Flutter AOT
/// snapshotter crash (flutter/flutter#188060) from compiling it into a
/// release snapshot.
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
