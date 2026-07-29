import 'package:dio/dio.dart';
import 'package:dio_request_inspector/dio_request_inspector.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';

/// Real [InspectorHost] backed by `package:dio_request_inspector`.
///
/// Wired ONLY by the development entrypoint (`lib/main_dev.dart`), so this file
/// — and the inspector package — is compiled exclusively into development
/// graphs and is never reached from the production entrypoint. That keeps the
/// package out of release AOT (avoiding flutter/flutter#188060) while keeping
/// the inspector fully functional in development.
///
/// The runtime dev-only gate is preserved here exactly as the composition root
/// previously applied it: the underlying [DioRequestInspector] is constructed
/// ONLY when development tools are enabled AND a backend URL is configured.
/// Dev builds that are not in dev-tools/backend mode behave exactly as before
/// (the host is inert: [enabled] is false, [wrap] passes the child through,
/// [attachInterceptor] is a no-op, [navigatorObservers] is empty).
final class RealInspectorHost implements InspectorHost {
  RealInspectorHost({
    required bool developmentToolsEnabled,
    Uri? backendBaseUrl,
  }) : _inspector = (developmentToolsEnabled && backendBaseUrl != null)
           ? DioRequestInspector(isInspectorEnabled: true)
           : null;

  /// The underlying inspector singleton, or null when the runtime dev-only gate
  /// is not satisfied. The package returns one shared instance; null means the
  /// dev overlay is inert for this launch (no backend / dev tools disabled).
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
    // The package exposes one shared static observer bound to the singleton.
    return <NavigatorObserver>[DioRequestInspector.navigatorObserver];
  }
}
