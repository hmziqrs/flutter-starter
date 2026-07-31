import 'package:flutter/foundation.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';

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

  @visibleForTesting
  RemoteConfigFeatureFlagsSource.withClient(this._client, this._buildInfo)
    : _current = const FeatureFlags.defaults();

  final RemoteConfigClient _client;
  final AppBuildInfo _buildInfo;

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
