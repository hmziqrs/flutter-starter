import 'package:dio/dio.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/firebase/firebase_performance_dio_interceptor.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

Dio buildAppDio(Uri baseUrl, {InspectorHost? inspectorHost, AppLogger? logger}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      validateStatus: (_) => true,
    ),
  );
  dio.interceptors.add(FirebasePerformanceDioInterceptor(logger: logger));
  inspectorHost?.attachInterceptor(dio);
  return dio;
}
