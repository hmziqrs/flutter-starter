import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_repository.dart';

/// In-memory [OtpRepository] for the no-backend production default and unit
/// tests.
///
/// Mirrors `InMemoryAuthRepository` / `InMemorySettingsStore`. Honors the
/// no-backend rule (C2) and the honest-feedback guardrail: `issue` / `verify` /
/// `resend` all surface `OtpRepositoryException.notConnected` and **never fake
/// success** — no issued code, no faked `valid`, no silent resend. The OTP
/// screen therefore stays a faithful static demo until a consumer wires the
/// optional real HTTP adapter.
///
/// This dual-purpose default is distinct from genuinely test-only fakes: it is
/// constructed in `AppDependencies.production` and `AppDependencies.inMemory`,
/// and is the production default until an endpoint is configured. A test that
/// wants to drive the live verify paths injects a fake [OtpRepository] override
/// instead (never a Mocktail of success in a production code path).
final class InMemoryOtpRepository implements OtpRepository {
  const InMemoryOtpRepository();

  @override
  Future<OtpIssueResult> issue({
    required OtpPurpose purpose,
    required String identifier,
  }) async {
    // No backend: surface notConnected rather than fabricating an issued code.
    throw const OtpRepositoryException.notConnected();
  }

  @override
  Future<OtpVerifyResult> verify({
    required String identifier,
    required String code,
  }) async {
    // No backend: surface notConnected rather than fabricating a valid result.
    throw const OtpRepositoryException.notConnected();
  }

  @override
  Future<OtpIssueResult> resend({required String identifier}) async {
    // No backend: surface notConnected rather than fabricating a resend. A
    // silent no-op would let the UI believe a new code was sent.
    throw const OtpRepositoryException.notConnected();
  }
}
