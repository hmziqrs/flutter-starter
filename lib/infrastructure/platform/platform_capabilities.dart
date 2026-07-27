import 'package:flutter/foundation.dart';

enum AppTvPlatform {
  none,
  androidTv,
  tvOS,
}

/// Immutable platform and packaging facts resolved before application startup.
@immutable
final class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.isWeb,
    required this.tvPlatform,
  });

  const PlatformCapabilities.nonTelevision({
    this.platform = 'test',
    this.isWeb = false,
  }) : tvPlatform = AppTvPlatform.none;

  final String platform;
  final bool isWeb;
  final AppTvPlatform tvPlatform;

  bool get isTelevision => tvPlatform != AppTvPlatform.none;

  String get redactedSummary => 'platform=$platform, web=$isWeb, tv=${tvPlatform.name}';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlatformCapabilities &&
            platform == other.platform &&
            isWeb == other.isWeb &&
            tvPlatform == other.tvPlatform;
  }

  @override
  int get hashCode => Object.hash(platform, isWeb, tvPlatform);
}
