import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';

/// In-memory [OtpRepository] for the no-backend production default and unit
/// tests. `issue` / `verify` / `resend` all surface `notConnected` and never
/// fake success, so the OTP screen stays a faithful static demo until a
/// consumer wires a real HTTP adapter.
final class InMemoryOtpRepository implements OtpRepository {
  const InMemoryOtpRepository();

  @override
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  }) async {
    throw const OtpRepositoryException.notConnected();
  }

  @override
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  }) async {
    throw const OtpRepositoryException.notConnected();
  }

  @override
  Future<OtpIssueResult> resend({required String identifier}) async {
    throw const OtpRepositoryException.notConnected();
  }
}
