import 'package:cross_file/cross_file.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:starter/infrastructure/sharing/share_service.dart';

class SharePlusShareService implements ShareService {
  const SharePlusShareService();

  @override
  Future<ShareResult> shareText(String text) async {
    if (text.isEmpty) {
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

  static ShareResult _mapStatus(sp.ShareResultStatus status) {
    return switch (status) {
      sp.ShareResultStatus.success => ShareResult.success,
      sp.ShareResultStatus.dismissed => ShareResult.cancelled,
      sp.ShareResultStatus.unavailable => ShareResult.unavailable,
    };
  }
}
