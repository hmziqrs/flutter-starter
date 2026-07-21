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

  String get redactedSummary => 'platform=$platform, web=$isWeb, filesystem=$supportsFileSystem';
}
