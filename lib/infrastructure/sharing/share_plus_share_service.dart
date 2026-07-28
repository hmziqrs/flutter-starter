import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:starter/infrastructure/sharing/share_service.dart';

/// Production [ShareService] backed by the `share_plus` OS share sheet.
///
/// Constructed in `AppDependencies.production` (the composition root) only on
/// platforms with a native share target (see [shareTargetAvailable]); web /
/// unsupported desktop / integration-test runs use `NoopShareService` instead,
/// selected from `PlatformCapabilities`. The plugin is never referenced outside
/// this adapter — every consumer reads the typed [ShareResult] surface
/// (C2: no widget calls a plugin directly).
///
/// Both methods degrade honestly inside `try/on Object` (C13: never fake
/// success). `share_plus`'s own [sp.ShareResult] status is mapped to the typed
/// [ShareResult] variants: a plugin `unavailable` (no result callback supported
/// on the platform) is surfaced honestly as [ShareResult.unavailable] rather
/// than fabricated as `success`, and a `dismissed` sheet is surfaced as
/// [ShareResult.cancelled].
class SharePlusShareService implements ShareService {
  const SharePlusShareService();

  @override
  Future<ShareResult> shareText(String text) async {
    if (text.isEmpty) {
      // share_plus rejects empty text with ArgumentError; surface honestly.
      return ShareResult.unavailable;
    }
    try {
      final result = await sp.SharePlus.instance.share(sp.ShareParams(text: text));
      return _mapStatus(result.status);
    } on Object {
      return ShareResult.unavailable;
    }
  }

  @override
  Future<ShareResult> shareFiles(List<XFile> files) async {
    if (files.isEmpty) {
      return ShareResult.unavailable;
    }
    try {
      final result = await sp.SharePlus.instance.share(sp.ShareParams(files: files));
      return _mapStatus(result.status);
    } on Object {
      return ShareResult.unavailable;
    }
  }

  /// Maps the plugin's [sp.ShareResultStatus] to the typed [ShareResult].
  /// Exhaustive so a future plugin variant is handled explicitly here rather
  /// than falling through to a default that could fabricate success.
  static ShareResult _mapStatus(sp.ShareResultStatus status) {
    return switch (status) {
      sp.ShareResultStatus.success => ShareResult.success,
      sp.ShareResultStatus.dismissed => ShareResult.cancelled,
      sp.ShareResultStatus.unavailable => ShareResult.unavailable,
    };
  }
}
