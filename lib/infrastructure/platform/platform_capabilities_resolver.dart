import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tvos/flutter_tvos.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

final class PlatformCapabilitiesResolver {
  const PlatformCapabilitiesResolver([
    this._androidChannel = const MethodChannel(_androidChannelName),
    this.androidProbeTimeout = const Duration(seconds: 2),
  ]);

  static const _androidChannelName = 'starter/platform_capabilities';
  static const _isAndroidTvMethod = 'isAndroidTv';

  final MethodChannel _androidChannel;
  final Duration androidProbeTimeout;

  Future<PlatformCapabilities> resolve() async {
    if (kIsWeb) {
      return const PlatformCapabilities(
        platform: 'web',
        isWeb: true,
        tvPlatform: AppTvPlatform.none,
      );
    }

    if (TvOSInfo.isTvOS) {
      return const PlatformCapabilities(
        platform: 'tvOS',
        isWeb: false,
        tvPlatform: AppTvPlatform.tvOS,
      );
    }

    final targetPlatform = defaultTargetPlatform;
    if (targetPlatform != TargetPlatform.android) {
      return PlatformCapabilities(
        platform: targetPlatform.name,
        isWeb: false,
        tvPlatform: AppTvPlatform.none,
      );
    }

    final isAndroidTv =
        await _androidChannel.invokeMethod<bool>(_isAndroidTvMethod).timeout(androidProbeTimeout) ??
        false;
    return PlatformCapabilities(
      platform: targetPlatform.name,
      isWeb: false,
      tvPlatform: isAndroidTv ? AppTvPlatform.androidTv : AppTvPlatform.none,
    );
  }
}
