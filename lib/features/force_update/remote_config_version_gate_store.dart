import 'package:flutter/foundation.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed [VersionGateStore] — the update-blocker typed
/// port's real impl.
///
/// This file lives with its feature because the typed PORT lives with its
/// feature (C4: `lib/features/{force_update}/`, mirroring `SettingsStore`). It
/// does **not** own a backend connection: it reads only the `versionPolicy`
/// slice from the single shared [RemoteConfigClient] under
/// `lib/infrastructure/remote_config/` — the one backend wrapper that the
/// future `FeatureFlagsSource` and `ExperimentSource` real impls will also read
/// from (one backend, three typed surfaces). The reader therefore never opens
/// its own `HttpClient` and never duplicates the `GET /v1/remote-config`
/// round-trip.
///
/// Constructed at the composition root only when a consumer wires the backend;
/// never the default. Every backend interaction degrades to
/// [UpdateRequirementNone] on any failure — a policy that cannot be fetched or
/// parsed must never fabricate a hard or soft block (C2: never fake success, and
/// never hard-lock a user we cannot verify).
final class RemoteConfigVersionGateStore implements VersionGateStore {
  /// Constructs a store that reads the `versionPolicy` slice from a
  /// [RemoteConfigClient] configured with [baseUrl], [deviceId], and [timeout].
  RemoteConfigVersionGateStore({
    required Uri baseUrl,
    String? deviceId,
    Duration timeout = const Duration(seconds: 5),
  }) : this.withClient(
         RemoteConfigClient(baseUrl: baseUrl, deviceId: deviceId, timeout: timeout),
       );

  /// Constructs a store backed by an explicit [client]. The default
  /// constructor redirects here; tests inject a stub client through this form.
  @visibleForTesting
  RemoteConfigVersionGateStore.withClient(this.client);

  /// The single shared remote-config backend wrapper (C4).
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
