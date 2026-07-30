import 'package:cross_file/cross_file.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

/// Deterministic "no share target" [ShareService], selected for web,
/// unsupported desktop, and test/golden runs (keyed off
/// `shareTargetAvailable`). Returns [ShareResult.unavailable] rather than
/// faking a successful share; `SharePlusShareService` is the real impl.
class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<ShareResult> shareText(String text) async => ShareResult.unavailable;

  @override
  Future<ShareResult> shareFiles(List<XFile> files) async => ShareResult.unavailable;
}
