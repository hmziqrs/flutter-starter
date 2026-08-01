import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

abstract interface class InspectorHost {
  Widget wrap(Widget child);

  void attachInterceptor(Dio dio);

  List<NavigatorObserver> get navigatorObservers;

  bool get enabled;
}
