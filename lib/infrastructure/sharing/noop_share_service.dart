import 'package:cross_file/cross_file.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

/// Deterministic, honest "no share target" [ShareService].
///
/// The composition root selects this adapter for web, unsupported desktop, and
/// integration-test / golden runs (keyed off `shareTargetAvailable`, never a
/// global) so the starter stays green and goldens stay stable without ever
/// popping a real OS share sheet. Per the no-backend / honest-feedback contracts
/// (C2 / C13) it returns [ShareResult.unavailable] from both methods — it
/// **never fakes a successful share**. There is no optional real impl behind
/// it; the production path on a supported platform uses
/// `SharePlusShareService` instead.
class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<ShareResult> shareText(String text) async => ShareResult.unavailable;

  @override
  Future<ShareResult> shareFiles(List<XFile> files) async => ShareResult.unavailable;
}
