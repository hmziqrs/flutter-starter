import 'package:cross_file/cross_file.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<ShareResult> shareText(String text) async => ShareResult.unavailable;

  @override
  Future<ShareResult> shareFiles(List<XFile> files) async => ShareResult.unavailable;
}
