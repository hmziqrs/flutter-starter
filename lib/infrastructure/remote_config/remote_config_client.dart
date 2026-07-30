import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// The decoded remote-config payload sliced into the typed surfaces the
/// feature-owned ports read from. Each slice is `null` when the backend
/// omitted it; readers degrade to their no-backend default. This type only
/// exposes the shared payload shape — it does not interpret any slice.
@immutable
final class RemoteConfigPayload {
  const RemoteConfigPayload(this._payload);

  final Map<String, Object?> _payload;

  /// Feature-flag slice consumed by `FeatureFlagsSource`.
  Map<String, Object?>? get flags => _slice('flags');

  /// Version-policy slice consumed by `RemoteConfigVersionGateStore`.
  Map<String, Object?>? get versionPolicy => _slice('versionPolicy');

  /// Experiment slice consumed by `ExperimentSource`.
  Map<String, Object?>? get experiments => _slice('experiments');

  /// Backend revision token (opaque to clients).
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

/// The single shared backend wrapper for the remote-config family. Performs
/// the one `GET /v1/remote-config` round-trip and decodes it into the typed
/// [RemoteConfigPayload] slices. Each feature-owned typed port reads only its
/// own slice; no reader opens its own HTTP client — all share the injected
/// [Dio] (built via [buildAppDio] when no instance is supplied).
///
/// Every interaction is wrapped in `try/on Object` and returns `null` on any
/// failure so callers degrade to their no-backend default.
final class RemoteConfigClient {
  RemoteConfigClient({
    required Uri baseUrl,
    this.deviceId,
    this.timeout = const Duration(seconds: 5),
    Dio? dio,
  }) : _dio = dio ?? buildAppDio(baseUrl) {
    // Only the internally-built instance gets our timeouts; an injected Dio
    // is owned by the composition root, which sets its own.
    if (dio == null) {
      _dio.options
        ..connectTimeout = timeout
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
    }
  }

  /// Optional device identifier sent as the `deviceId` query hint.
  final String? deviceId;

  /// Per-request connect / send / read timeout (applied to the built Dio).
  final Duration timeout;

  final Dio _dio;

  /// Fetches and decodes the remote-config payload, or `null` on any failure
  /// (network error, non-200 status, malformed body).
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
