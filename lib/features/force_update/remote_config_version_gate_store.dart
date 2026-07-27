import 'dart:convert';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Optional remote-config-backed [VersionGateStore].
///
/// Constructed at the composition root only when a consumer wires the backend;
/// never the default. It is update-blocker's reader on the shared
/// remote-config family (C4): it reads only the `versionPolicy` slice of the
/// single `GET /v1/remote-config` response served by `tools/test_server` (C9)
/// and mapped via `pub_semver` against [AppBuildInfo.version].
///
/// Every backend interaction is wrapped in `try/on Object` and degrades to
/// [UpdateRequirementNone] on any failure — a policy that cannot be fetched or
/// parsed must never fabricate a hard or soft block (C2: never fake success, and
/// never hard-lock a user we cannot verify).
final class RemoteConfigVersionGateStore implements VersionGateStore {
  RemoteConfigVersionGateStore({
    required this.baseUrl,
    this.deviceId,
    this.timeout = const Duration(seconds: 5),
  });

  /// Base URL of the remote-config backend (no `/v1/remote-config` suffix).
  final Uri baseUrl;

  /// Optional device identifier sent as the `deviceId` query hint.
  final String? deviceId;

  /// Per-request connect / read timeout.
  final Duration timeout;

  String? _storeUrl;

  @override
  String? get storeUrl => _storeUrl;

  @override
  Future<UpdateRequirement> check(AppBuildInfo buildInfo) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(_endpoint(buildInfo)).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        return const UpdateRequirementNone();
      }
      return _map(body, buildInfo);
    } on Object {
      return const UpdateRequirementNone();
    } finally {
      client.close(force: true);
    }
  }

  Uri _endpoint(AppBuildInfo buildInfo) {
    final basePath = baseUrl.path;
    final prefix = basePath.isEmpty || basePath == '/' ? '' : basePath;
    final query = <String, String>{
      'platform': Platform.operatingSystem,
      'version': buildInfo.version,
    };
    final id = deviceId;
    if (id != null) {
      query['deviceId'] = id;
    }
    return baseUrl.replace(
      path: '$prefix/v1/remote-config',
      queryParameters: query,
    );
  }

  UpdateRequirement _map(String body, AppBuildInfo buildInfo) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return const UpdateRequirementNone();
    }
    if (decoded is! Map<String, Object?>) {
      return const UpdateRequirementNone();
    }
    final policy = decoded['versionPolicy'];
    if (policy is! Map<String, Object?>) {
      return const UpdateRequirementNone();
    }

    final hardBelow = _parseVersion(policy['hardBlockBelow']);
    final softBelow = _parseVersion(policy['softBlockBelow']);
    final storeUrl = policy['storeUrl'];
    // A block without a store deep-link cannot offer an update path; treat as
    // none rather than trapping the user with no escape.
    if (storeUrl is! String) {
      return const UpdateRequirementNone();
    }
    _storeUrl = storeUrl;

    final installed = _parseVersion(buildInfo.version);
    if (installed == null) {
      return const UpdateRequirementNone();
    }

    final latestVersion = _asString(policy['latestVersion']) ?? buildInfo.version;
    final message = _asString(policy['message']);
    final minVersion = _asString(policy['minVersion']);

    if (hardBelow != null && installed < hardBelow) {
      return UpdateRequirementHard(
        minVersion: minVersion ?? hardBelow.toString(),
        latestVersion: latestVersion,
        storeUrl: storeUrl,
        message: message,
      );
    }
    if (softBelow != null && installed < softBelow) {
      return UpdateRequirementSoft(
        minVersion: minVersion ?? softBelow.toString(),
        latestVersion: latestVersion,
        storeUrl: storeUrl,
        message: message,
      );
    }
    return const UpdateRequirementNone();
  }

  static Version? _parseVersion(Object? raw) {
    final value = _asString(raw);
    if (value == null) {
      return null;
    }
    try {
      return Version.parse(value);
    } on FormatException {
      return null;
    }
  }

  static String? _asString(Object? raw) {
    if (raw is String) {
      return raw;
    }
    return null;
  }
}
