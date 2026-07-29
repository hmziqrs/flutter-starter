import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

/// No-op [InspectorHost] used by the production entrypoint.
///
/// Deliberately does NOT import `package:dio_request_inspector`, so the
/// inspector package's Dart code is absent from the release AOT graph. This is
/// what avoids the Flutter AOT snapshotter crash (flutter/flutter#188060)
/// triggered by compiling dio_request_inspector into a release snapshot.
///
/// Every member is a no-op / empty / disabled: [wrap] passes the child through,
/// [attachInterceptor] does nothing, [navigatorObservers] is empty, and
/// [enabled] is always false. Used in production, in tests (the default), and
/// in any build that does not wire the real development host.
final class StubInspectorHost implements InspectorHost {
  const StubInspectorHost();

  @override
  Widget wrap(Widget child) => child;

  @override
  void attachInterceptor(Dio dio) {
    // Intentional no-op: no inspector in this build graph.
  }

  @override
  List<NavigatorObserver> get navigatorObservers => const <NavigatorObserver>[];

  @override
  bool get enabled => false;
}
