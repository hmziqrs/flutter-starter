import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// The dev-only HTTP inspector abstraction.
///
/// The concrete implementation is selected by the build ENTRYPOINT, not at
/// runtime:
/// - `StubInspectorHost` (no `dio_request_inspector` import) is wired by the
///   production entrypoint (`lib/main.dart`), so the package's Dart code is
///   never compiled into a release AOT graph.
/// - `RealInspectorHost` (imports `dio_request_inspector`) is wired by the
///   development entrypoint (`lib/main_dev.dart`), keeping the inspector fully
///   functional in development.
///
/// NOTE on the conditional-import approach: the original plan was a
/// config-driven (`--dart-define=INSPECTOR=true`) conditional export barrel:
///   `export 'stub.dart' if (env.INSPECTOR == 'true') 'real.dart';`
/// That does NOT work in Dart. Conditional import/export conditions can only
/// test platform-library availability (`dart.library.*`); user `--dart-define`
/// values are exposed to `String.fromEnvironment` but are NOT provided as
/// conditional-import keys (dart.dev/tools/pub/create-packages: "Currently,
/// only keys of the form `dart.library.name` are provided"). Verified
/// empirically against this toolchain (Flutter 3.44.7): `env.INSPECTOR` always
/// evaluates to the default regardless of the dart-define. Hence the
/// entrypoint-based selection used here, which is the Flutter idiom for
/// excluding source from one build flavor while keeping it in another.
///
/// Both implementations satisfy this interface so the shared composition root
/// (bootstrap / AppDependencies / App / buildAppDio) depends only on
/// [InspectorHost] and never on `package:dio_request_inspector` — that keeps
/// the release graph free of the inspector package entirely.
abstract interface class InspectorHost {
  /// Wraps the root [child] in the inspector overlay, or returns [child]
  /// unchanged when the inspector is inactive (stub, or a real host whose
  /// runtime dev-only gate disabled it).
  Widget wrap(Widget child);

  /// Attaches the inspector's Dio interceptor to [dio], or is a no-op when the
  /// inspector is inactive. Called once on the shared [Dio] so the overlay
  /// observes every HTTP round-trip in development.
  void attachInterceptor(Dio dio);

  /// Navigator observers the inspector needs to push its dashboard onto the
  /// router's navigator. Empty when the inspector is inactive.
  List<NavigatorObserver> get navigatorObservers;

  /// Whether the inspector is actually active (constructed and enabled).
  /// False for the stub and for a real host whose runtime dev-only gate
  /// (development tools + backend configured) is not satisfied.
  bool get enabled;
}
