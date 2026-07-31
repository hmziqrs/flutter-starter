import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

@immutable
final class RemoteConfigPayload {
  const RemoteConfigPayload(this._payload);

  final Map<String, Object?> _payload;

  Map<String, Object?>? get flags => _slice('flags');

  Map<String, Object?>? get versionPolicy => _slice('versionPolicy');

  Map<String, Object?>? get experiments => _slice('experiments');

  String? get revision => _asString(_payload['revision']);

  Map<String, Object?>? _slice(String key) {
    final value = _payload[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    return null;
  }

  static String? _asString(Object? raw) => raw is String ? raw : null;
}

final class RemoteConfigClient {
  RemoteConfigClient({
    required Uri baseUrl,
    this.deviceId,
    this.timeout = const Duration(seconds: 5),
    Dio? dio,
  }) : _dio = dio ?? buildAppDio(baseUrl) {
    if (dio == null) {
      _dio.options
        ..connectTimeout = timeout
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
    }
  }

  final String? deviceId;

  final Duration timeout;

  final Dio _dio;

  Future<RemoteConfigPayload?> fetch(AppBuildInfo buildInfo) async {
    final queryParameters = <String, String>{
      'platform': Platform.operatingSystem,
      'version': buildInfo.version,
    };
    final id = deviceId;
    if (id != null) {
      queryParameters['deviceId'] = id;
    }
    try {
      final response = await _dio.get<String>(
        '/v1/remote-config',
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final body = response.data ?? '';
      final Object? decoded;
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        return null;
      }
      if (decoded is! Map<String, Object?>) {
        return null;
      }
      return RemoteConfigPayload(decoded);
    } on Object {
      return null;
    }
  }
}
