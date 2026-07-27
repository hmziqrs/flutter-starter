import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Revision advertised to clients. Bump when the served payload changes (the
/// `ETag` is derived from this and must stay in lockstep).
const String revision = '1';

/// Entity tag derived from [revision]. Sent on every `200` and `304` so clients
/// can cache with `If-None-Match`.
final String _etag = '"$revision"';

/// The single cacheable remote-config payload (C9). The three remote-config
/// readers — `FeatureFlagsSource`, `VersionGateStore`, `ExperimentSource` —
/// each read their slice from this one response.
final Map<String, Object?> _payload = <String, Object?>{
  'flags': <String, Object?>{},
  'versionPolicy': <String, Object?>{
    'minVersion': null,
    'latestVersion': null,
    'hardBlockBelow': null,
    'softBlockBelow': null,
    'storeUrl': null,
    'message': null,
  },
  'experiments': <String, Object?>{},
  'revision': revision,
};

/// Mounts the remote-config contract (C9) onto [router]:
/// `GET /v1/remote-config?deviceId=&platform=&version=` -> cached payload, or
/// `304` when `If-None-Match` / `?rev=` matches.
void registerRoutes(Router router) {
  router.get('/v1/remote-config', _handle);
}

Response _handle(Request request) {
  // Conditional request via If-None-Match (RFC 7232). `*` always matches.
  final ifNoneMatch = request.headers['if-none-match'];
  if (ifNoneMatch == _etag || ifNoneMatch == '*') {
    return Response.notModified(headers: <String, String>{'etag': _etag});
  }

  // Conditional request via ?rev= query parameter (mobile-friendly cache hit).
  final requested = request.requestedUri.queryParameters['rev'];
  if (requested == revision) {
    return Response.notModified(headers: <String, String>{'etag': _etag});
  }

  return Response.ok(
    jsonEncode(_payload),
    headers: <String, String>{..._jsonHeaders, 'etag': _etag},
  );
}
