import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

/// Shared round-trip base for Dio-backed HTTP repositories.
///
/// Concrete subclasses keep their own status-bucket rules by overriding
/// [classify] (for status-bearing failures) and [throwNotConnected] (for the
/// no-status/unreachable case). The base owns the [dio] instance and the
/// [roundTripRaw] wrapper that converts [DioException]s into feature exceptions.
abstract base class AppHttpRepository {
  AppHttpRepository({required Uri baseUrl, Dio? dio}) : dio = dio ?? buildAppDio(baseUrl);

  /// The configured [Dio] instance used to issue requests.
  @protected
  final Dio dio;

  /// Classify a non-success [status] and throw the appropriate feature
  /// exception. Always throws (returns [Never]); subclasses must implement this
  /// with their own status-bucket rules.
  @protected
  Never classify(int status);

  /// Throw the exception used when the device cannot reach the server (no
  /// status code available). Always throws (returns [Never]).
  @protected
  Never throwNotConnected();

  /// Execute [send], translating a [DioException] into the subclass's feature
  /// exception via [classify] / [throwNotConnected]. The returned [Response] is
  /// handed back untouched so the caller can apply its own success/non-success
  /// handling.
  @protected
  Future<Response<String>> roundTripRaw(
    Future<Response<String>> Function() send,
  ) async {
    try {
      return await send();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        classify(status);
      }
      throwNotConnected();
    }
  }
}
