import 'package:flutter/foundation.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed [VersionGateStore]. Reads only the
/// `versionPolicy` slice from the shared [RemoteConfigClient]. Every backend
/// interaction degrades to [UpdateRequirementNone] on failure — a policy that
/// cannot be fetched or parsed must never fabricate a hard or soft block.
final class RemoteConfigVersionGateStore implements VersionGateStore {
  /// Reads the `versionPolicy` slice from a [RemoteConfigClient] configured
  /// with [baseUrl], [deviceId], and [timeout].
  RemoteConfigVersionGateStore({
    required Uri baseUrl,
    String? deviceId,
    Duration timeout = const Duration(seconds: 5),
  }) : this.withClient(
         RemoteConfigClient(baseUrl: baseUrl, deviceId: deviceId, timeout: timeout),
       );

  /// Constructs a store backed by an explicit [client]; tests inject a stub
  /// client through this form.
  @visibleForTesting
  RemoteConfigVersionGateStore.withClient(this.client);

  final RemoteConfigClient client;

  String? _storeUrl;

  @override
  String? get storeUrl => _storeUrl;

  @override
  Future<UpdateRequirement> check(AppBuildInfo buildInfo) async {
    final payload = await client.fetch(buildInfo);
    if (payload == null) {
      return const UpdateRequirementNone();
    }
    return _mapPolicy(payload.versionPolicy, buildInfo);
  }

  UpdateRequirement _mapPolicy(Map<String, Object?>? policy, AppBuildInfo buildInfo) {
    if (policy == null) {
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
