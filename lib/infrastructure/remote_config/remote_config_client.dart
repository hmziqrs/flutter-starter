import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// The decoded remote-config payload sliced into the typed surfaces that the
/// feature-owned ports read from (C4: one backend, three typed surfaces).
///
/// Each slice is `null` when the backend omitted it; readers degrade to their
/// no-backend default in that case (C2). This type only exposes the shared
/// payload shape — it does not interpret any slice. Per-feature value types
/// (`FeatureFlagsSource`, `ExperimentSource`) are owned by their features.
@immutable
final class RemoteConfigPayload {
  const RemoteConfigPayload(this._payload);

  final Map<String, Object?> _payload;

  /// Feature-flag slice consumed by `FeatureFlagsSource` (Wave 4).
  Map<String, Object?>? get flags => _slice('flags');

  /// Version-policy slice consumed by `RemoteConfigVersionGateStore`
  /// (update-blocker).
  Map<String, Object?>? get versionPolicy => _slice('versionPolicy');

  /// Experiment slice consumed by `ExperimentSource` (Wave 6).
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

/// The single shared backend wrapper for the remote-config family (C4).
///
/// Performs the one `GET /v1/remote-config` round-trip against the backend
/// served by `tools/test_server` (C9) and decodes it into the typed
/// [RemoteConfigPayload] slices. Each feature-owned typed port
/// (`VersionGateStore`, the future `FeatureFlagsSource` and `ExperimentSource`)
/// depends on this client and reads only its own slice — one backend, three
/// typed surfaces, three `InMemory` defaults. No reader opens its own HTTP
/// client; all share the injected [Dio] (built via [buildAppDio] when no
/// instance is supplied), which is the port multiplication C4 exists to
/// prevent.
///
/// Every interaction is wrapped in `try/on Object` and returns `null` on any
/// failure (network, non-200 status, parse) so callers degrade to their
/// no-backend default and never fabricate a result (C2: never fake success).
final class RemoteConfigClient {
  RemoteConfigClient({
    required Uri baseUrl,
    this.deviceId,
    this.timeout = const Duration(seconds: 5),
    Dio? dio,
  }) : _dio = dio ?? buildAppDio(baseUrl) {
    // Only the internally-built instance gets the adapter's own timeouts; an
    // injected Dio is owned by the composition root, which sets its own.
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
  /// (network error, non-200 status, malformed body). Readers degrade to their
  /// no-backend default rather than fabricating a partial result (C2).
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
