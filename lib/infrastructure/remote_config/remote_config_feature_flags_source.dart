import 'package:flutter/foundation.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

/// Optional remote-config-backed `FeatureFlagsSource`. Reads only the `flags`
/// slice from the one shared `RemoteConfigClient` — never opens its own
/// `HttpClient`.
///
/// Constructed at the composition root only when a consumer wires the
/// backend; never the default. Every backend interaction degrades to the
/// cached value (or `FeatureFlags.defaults`) on any failure. Because the
/// backend is poll-based, `changes` emits nothing; live refresh flows through
/// the controller's resume-driven `load`.
final class RemoteConfigFeatureFlagsSource implements FeatureFlagsSource {
  RemoteConfigFeatureFlagsSource({
    required Uri baseUrl,
    required AppBuildInfo buildInfo,
    String? deviceId,
    Duration timeout = const Duration(seconds: 5),
  }) : this.withClient(
         RemoteConfigClient(baseUrl: baseUrl, deviceId: deviceId, timeout: timeout),
         buildInfo,
       );

  /// Tests inject a stub client through this form.
  @visibleForTesting
  RemoteConfigFeatureFlagsSource.withClient(this._client, this._buildInfo)
    : _current = const FeatureFlags.defaults();

  final RemoteConfigClient _client;
  final AppBuildInfo _buildInfo;

  /// Last successfully decoded flags, returned on any backend failure.
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
