import 'package:dio/dio.dart';
import 'package:dio_request_inspector/dio_request_inspector.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

final class RealInspectorHost implements InspectorHost {
  RealInspectorHost({
    required bool developmentToolsEnabled,
    Uri? backendBaseUrl,
  }) : _inspector = (developmentToolsEnabled && backendBaseUrl != null)
           ? DioRequestInspector(isInspectorEnabled: true)
           : null;

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
