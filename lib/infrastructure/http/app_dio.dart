import 'package:dio/dio.dart';
import 'package:dio_request_inspector/dio_request_inspector.dart';

/// Builds a configured [Dio] for one adapter's [baseUrl].
///
/// The HTTP adapters classify response status themselves (401, 409, 429, 4xx,
/// 5xx each map to a different typed exception), so [BaseOptions.validateStatus]
/// accepts **every** status code: Dio never throws on a non-2xx response — the
/// adapter inspects `response.statusCode` and raises its own typed exception.
/// Transport failures (connection refused, timeouts, bad certificate, ...) still
/// surface as a [DioException]; each adapter maps that to its `notConnected`
/// kind. `responseType` defaults to [ResponseType.json] (overridden to
/// [ResponseType.plain] per-request by adapters that decode the body themselves
/// to preserve their exact parse semantics).
///
/// When [inspector] is supplied its interceptor is attached so the dev shell
/// (`DioRequestInspectorMain`) can observe every round-trip. The inspector is
/// optional; production / test graphs pass `null`.
///
/// This is the single seam the composition root uses to share one [Dio] (and
/// one inspector) across every adapter; the adapters themselves never construct
/// a `dart:io` `HttpClient`.
Dio buildAppDio(Uri baseUrl, {DioRequestInspector? inspector}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      // Explicit even though `ResponseType.json` is the Dio default: documents
      // the contract (Dio decodes JSON bodies) relied on by callers that do not
      // override it per-request.
      // ignore: avoid_redundant_argument_values
      responseType: ResponseType.json,
      // Adapters own status -> typed-exception mapping; Dio must not throw on
      // 4xx/409/429/5xx so the adapter can inspect the status itself.
      validateStatus: (_) => true,
    ),
  );
  if (inspector != null) {
    dio.interceptors.add(inspector.getDioRequestInterceptor());
  }
  return dio;
}
