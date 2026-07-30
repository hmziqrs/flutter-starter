import 'package:dio/dio.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/firebase/firebase_performance_dio_interceptor.dart';

/// Builds a configured [Dio] for one adapter's [baseUrl].
///
/// Adapters classify response status themselves (401, 409, 429, 4xx, 5xx map
/// to distinct typed exceptions), so [BaseOptions.validateStatus] accepts
/// every status code — Dio never throws on non-2xx. Transport failures still
/// surface as [DioException]; each adapter maps that to `notConnected`.
///
/// When [inspectorHost] is supplied its interceptor is attached so the dev
/// inspector overlay can observe every round-trip; it no-ops in production /
/// test graphs (`StubInspectorHost`).
///
/// The single seam the composition root uses to share one [Dio] across every
/// adapter — adapters never construct their own `dart:io` `HttpClient`.
Dio buildAppDio(Uri baseUrl, {InspectorHost? inspectorHost}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      // Explicit for documentation despite matching the Dio default.
      // ignore: avoid_redundant_argument_values
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );
  // Added before the optional dev inspector so it envelopes the full
  // round-trip (Dio runs response interceptors in reverse insertion order).
  // Self-no-ops on unsupported hosts (macOS / Linux / Windows).
  dio.interceptors.add(FirebasePerformanceDioInterceptor());
  inspectorHost?.attachInterceptor(dio);
  return dio;
}
