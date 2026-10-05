import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

enum ShareResult {
  success,

  unavailable,

  cancelled,
}

abstract interface class ShareService {
  Future<ShareResult> shareText(String text);

  Future<ShareResult> shareFiles(List<XFile> files);
}

final class ShareServiceException implements Exception {
  const ShareServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'ShareServiceException: $operation failed';
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => throw StateError('ShareService must be overridden at the composition root.'),
);

bool shareTargetAvailable(PlatformCapabilities capabilities) {
  if (capabilities.isWeb) return false;
  // PlatformCapabilities.platform carries the TargetPlatform name ('iOS',
  // 'android'), so match case-insensitively to keep real devices on the share
  // path regardless of spelling.
  final platform = capabilities.platform.toLowerCase();
  return platform == 'android' || platform == 'ios';
}
