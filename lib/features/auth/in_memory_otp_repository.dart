import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';

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
