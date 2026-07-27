import 'package:flutter/foundation.dart';

final class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.isWeb,
    required this.supportsFileSystem,
  });

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

  /// Whether the current platform is an Apple platform (iOS / macOS).
  ///
  /// Derived read-only from [platform] (no platform channel) so shared widgets
  /// keep a single platform seam when choosing Cupertino vs Material affordances
  /// (e.g. pull-to-refresh — see `AppRefreshIndicator` / `RefreshableListView`).
  /// Matches the existing read-only-derived-getter pattern: it adds no state and
  /// no side effects.
  bool get isApplePlatform =>
      platform == TargetPlatform.iOS.name || platform == TargetPlatform.macOS.name;

  String get redactedSummary => 'platform=$platform, web=$isWeb, filesystem=$supportsFileSystem';
}
