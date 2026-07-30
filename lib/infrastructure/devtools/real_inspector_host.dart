import 'package:dio/dio.dart';
import 'package:dio_request_inspector/dio_request_inspector.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

/// Real [InspectorHost] backed by `package:dio_request_inspector`. Wired only
/// by the development entrypoint (`lib/main_dev.dart`), keeping the package
/// out of release AOT (avoiding flutter/flutter#188060).
///
/// The underlying [DioRequestInspector] is constructed only when development
/// tools are enabled and a backend URL is configured; otherwise the host is
/// inert ([enabled] false, [wrap] passes the child through,
/// [attachInterceptor] a no-op, [navigatorObservers] empty).
final class RealInspectorHost implements InspectorHost {
  RealInspectorHost({
    required bool developmentToolsEnabled,
    Uri? backendBaseUrl,
  }) : _inspector = (developmentToolsEnabled && backendBaseUrl != null)
           ? DioRequestInspector(isInspectorEnabled: true)
           : null;

  /// The underlying inspector singleton, or null when the dev-only gate is
  /// not satisfied.
  final DioRequestInspector? _inspector;

  @override
  bool get enabled => _inspector != null;

  @override
  Widget wrap(Widget child) {
    final inspector = _inspector;
    if (inspector == null) return child;
    return DioRequestInspectorMain(inspector: inspector, child: child);
  }

  @override
  void attachInterceptor(Dio dio) {
    final inspector = _inspector;
    if (inspector == null) return;
    dio.interceptors.add(inspector.getDioRequestInterceptor());
  }

  @override
  List<NavigatorObserver> get navigatorObservers {
    if (_inspector == null) return const <NavigatorObserver>[];
    return <NavigatorObserver>[DioRequestInspector.navigatorObserver];
  }
}
