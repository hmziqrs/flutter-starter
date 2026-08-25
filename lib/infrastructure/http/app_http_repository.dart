import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

abstract base class AppHttpRepository {
  AppHttpRepository({required Uri baseUrl, Dio? dio}) : dio = dio ?? buildAppDio(baseUrl);

  @protected
  final Dio dio;

  @protected
  Never classify(int status);

  @protected
  Never throwNotConnected();

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
