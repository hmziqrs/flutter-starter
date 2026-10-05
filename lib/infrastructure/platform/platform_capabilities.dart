import 'package:flutter/foundation.dart';

enum AppTvPlatform {
  none,
  androidTv,
  tvOS,
}

@immutable
final class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.isWeb,
    this.supportsFileSystem = true,
    this.tvPlatform = AppTvPlatform.none,
  });

  const PlatformCapabilities.nonTelevision({
    this.platform = 'test',
    this.isWeb = false,
  }) : supportsFileSystem = true,
       tvPlatform = AppTvPlatform.none;

  factory PlatformCapabilities.current() {
    return PlatformCapabilities(
      platform: defaultTargetPlatform.name,
      isWeb: kIsWeb,
      supportsFileSystem: !kIsWeb,
    );
  }

  final String platform;
  final bool isWeb;
  final bool supportsFileSystem;
  final AppTvPlatform tvPlatform;

  bool get isApplePlatform {
    // The resolver emits TargetPlatform names plus its own spellings ('tvOS',
    // 'web'), so match case-insensitively and include tvOS — an Apple platform.
    switch (platform.toLowerCase()) {
      case 'ios' || 'macos' || 'tvos':
        return true;
      default:
        return false;
    }
  }

  bool get isTelevision => tvPlatform != AppTvPlatform.none;

  String get redactedSummary =>
      'platform=$platform, web=$isWeb, filesystem=$supportsFileSystem, tv=${tvPlatform.name}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlatformCapabilities &&
            platform == other.platform &&
            isWeb == other.isWeb &&
            supportsFileSystem == other.supportsFileSystem &&
            tvPlatform == other.tvPlatform;
  }

  @override
  int get hashCode => Object.hash(platform, isWeb, supportsFileSystem, tvPlatform);
}
