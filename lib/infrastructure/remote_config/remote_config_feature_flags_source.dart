import 'package:flutter/foundation.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed `FeatureFlagsSource` — the feature-flags typed
/// port's real impl.
///
/// This adapter lives under `lib/infrastructure/remote_config/` (C4: the single
/// shared backend wrapper and its slice readers live here) and reads only the
/// `flags` slice from the one shared `RemoteConfigClient`. It does **not** own a
/// backend connection and never opens its own `HttpClient` — that is the port
/// multiplication C4 exists to prevent. The feature-owned typed port
/// (`FeatureFlagsSource`) and its `InMemoryFeatureFlagsSource` default live with
/// the feature under `lib/features/feature_flags/`.
///
/// Constructed at the composition root only when a consumer wires the backend;
/// never the default. Every backend interaction degrades to the cached value
/// (or `FeatureFlags.defaults`) on any failure — a flags payload that cannot be
/// fetched or parsed must never fabricate an enabled flag (C2: never fake
/// success). Because the backend is poll-based (one `GET /v1/remote-config`
/// round-trip per `load`), `changes` emits nothing; live refresh flows through
/// the controller's resume-driven `load`.
final class RemoteConfigFeatureFlagsSource implements FeatureFlagsSource {
  /// Constructs a source that reads the `flags` slice from a `RemoteConfigClient`
  /// configured with [baseUrl], [deviceId], and [timeout]. [buildInfo] is the
  /// installed build sent as the `version` query hint.
  RemoteConfigFeatureFlagsSource({
    required Uri baseUrl,
    required AppBuildInfo buildInfo,
    String? deviceId,
    Duration timeout = const Duration(seconds: 5),
  }) : this.withClient(
         RemoteConfigClient(baseUrl: baseUrl, deviceId: deviceId, timeout: timeout),
         buildInfo,
       );

  /// Constructs a source backed by an explicit client. The default constructor
  /// redirects here; tests inject a stub client through this form.
  @visibleForTesting
  RemoteConfigFeatureFlagsSource.withClient(this._client, this._buildInfo)
    : _current = const FeatureFlags.defaults();

  final RemoteConfigClient _client;
  final AppBuildInfo _buildInfo;

  /// Last successfully decoded flags (or `FeatureFlags.defaults` before the
  /// first successful fetch). Returned on any backend failure so callers degrade
  /// rather than fabricate.
  FeatureFlags _current;

  @override
  Future<FeatureFlags> load() async {
    final payload = await _client.fetch(_buildInfo);
    if (payload == null) {
      return _current;
    }
    final next = FeatureFlags.fromSlice(payload.flags);
    _current = next;
    return next;
  }

  @override
  Stream<FeatureFlags> changes() => const Stream<FeatureFlags>.empty();
}
