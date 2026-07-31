import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

/// Selected by entrypoint, not conditional import (which tests
/// `dart.library.*`, not dart-defines), to exclude from release AOT.
abstract interface class InspectorHost {
  Widget wrap(Widget child);

  void attachInterceptor(Dio dio);

  List<NavigatorObserver> get navigatorObservers;

  bool get enabled;
}
