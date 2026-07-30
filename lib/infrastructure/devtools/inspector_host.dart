import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// The dev-only HTTP inspector abstraction.
///
/// Selected by build ENTRYPOINT, not runtime: `StubInspectorHost` (no
/// `dio_request_inspector` import) is wired by `lib/main.dart` so the package
/// is never compiled into a release AOT graph; `RealInspectorHost` is wired
/// by `lib/main_dev.dart`.
///
/// A `--dart-define`-gated conditional export (`export 'stub.dart' if
/// (env.INSPECTOR == 'true') 'real.dart'`) does NOT work in Dart: conditional
/// import/export only tests `dart.library.*` availability, not
/// `String.fromEnvironment` values — hence entrypoint-based selection.
///
/// Both implementations satisfy this interface so the composition root
/// depends only on [InspectorHost], keeping the release graph free of the
/// inspector package.
abstract interface class InspectorHost {
  /// Wraps the root [child] in the inspector overlay, or returns it unchanged
  /// when the inspector is inactive.
  Widget wrap(Widget child);

  /// Attaches the inspector's Dio interceptor to [dio], or no-ops when
  /// inactive. Called once on the shared [Dio].
  void attachInterceptor(Dio dio);

  /// Navigator observers the inspector needs to push its dashboard. Empty
  /// when inactive.
  List<NavigatorObserver> get navigatorObservers;

  /// Whether the inspector is actually active (constructed and enabled).
  bool get enabled;
}
