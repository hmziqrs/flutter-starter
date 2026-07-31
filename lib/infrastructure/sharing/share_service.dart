import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
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
  return capabilities.platform == TargetPlatform.android.name ||
      capabilities.platform == TargetPlatform.iOS.name;
}
