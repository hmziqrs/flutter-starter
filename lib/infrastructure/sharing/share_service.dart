import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

/// The structured outcome of a share attempt. Consumers exhaustively switch
/// over the three variants.
enum ShareResult {
  /// The share sheet opened and the user completed the share (or the OS sheet
  /// dismissed without an explicit cancellation signal).
  success,

  /// The current platform has no native share target.
  unavailable,

  /// The user explicitly cancelled the share sheet (only when the OS
  /// distinguishes cancellation from completion).
  cancelled,
}

/// Native share-sheet port. Production adapter (`SharePlusShareService`) uses
/// `share_plus` directly; the noop default reports [ShareResult.unavailable]
/// honestly rather than faking a successful share.
///
/// `List<XFile>` matches `share_plus`'s native `shareXFiles` API.
abstract interface class ShareService {
  /// Opens the OS share sheet with [text]. Never throws — degrades to
  /// [ShareResult.unavailable].
  Future<ShareResult> shareText(String text);

  /// Opens the OS share sheet sharing [files]. Never throws — degrades to
  /// [ShareResult.unavailable].
  Future<ShareResult> shareFiles(List<XFile> files);
}

/// Thrown by [ShareService] implementations only for programmer errors (never
/// for share-sheet failures, which degrade to [ShareResult.unavailable]).
final class ShareServiceException implements Exception {
  const ShareServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'ShareServiceException: $operation failed';
}

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (`SharePlusShareService` where a native share target
/// exists, `NoopShareService` otherwise).
final shareServiceProvider = Provider<ShareService>(
  (ref) => throw StateError('ShareService must be overridden at the composition root.'),
);

/// Whether the OS exposes a native share target, consulted by the composition
/// root to pick an adapter. Desktop `share_plus` support is partial and
/// OS-release-dependent, so it is treated as unavailable here.
bool shareTargetAvailable(PlatformCapabilities capabilities) {
  if (capabilities.isWeb) return false;
  return capabilities.platform == TargetPlatform.android.name ||
      capabilities.platform == TargetPlatform.iOS.name;
}
