import 'package:dio/dio.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/firebase/firebase_performance_dio_interceptor.dart';

Dio buildAppDio(Uri baseUrl, {InspectorHost? inspectorHost}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      // Dio default; retained for clarity.
      // ignore: avoid_redundant_argument_values
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );
  dio.interceptors.add(FirebasePerformanceDioInterceptor());
  inspectorHost?.attachInterceptor(dio);
  return dio;
}
