import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// In-memory [AuthRepository] for the no-backend production default and unit
/// tests.
///
/// Mirrors `InMemorySettingsStore` / `InMemoryVersionGateStore`. Honors the
/// no-backend rule (C2) and the honest-feedback guardrail: `login` / `refresh`
/// / `logout` all surface `AuthException.notConnected` when no authenticated
/// session has been seeded, and **never fake success**. Tests (and the dev
/// gallery) seed a session to drive the authenticated paths; production runs
/// with an unseeded instance so every auth action surfaces
/// `common.notConnected` until the consumer wires the optional real HTTP
/// adapter.
///
/// This dual-purpose default is distinct from genuinely test-only fakes: it is
/// constructed in `AppDependencies.production` and `AppDependencies.inMemory`,
/// and is the production default until an endpoint is configured.
final class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthSession? seed}) : _session = seed;

  AuthSession? _session;

  /// The currently held session (anonymous when nothing is seeded). Exposed
  /// for assertions in unit tests; never read by production code paths.
  AuthSession get current => _session ?? const AuthAnonymous();

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    final session = _session;
    if (session is! AuthAuthenticated) {
      // No backend: surface notConnected rather than fabricating a session.
      throw const AuthException.notConnected();
    }
    // The in-memory fake returns the seeded session regardless of credentials.
    // The real adapter (and the test server) issue a fresh session from the
    // credentials; the contract — caller persists the returned refresh token —
    // is identical.
    return session;
  }

  @override
  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  }) async {
    // No backend: the no-backend default cannot create an account — surface
    // notConnected (C2) rather than fabricating an OTP issue handle.
    throw const AuthException.notConnected();
  }

  @override
  Future<AuthSession> refresh(AuthSession session) async {
    final held = _session;
    if (held is! AuthAuthenticated) {
      throw const AuthException.notConnected();
    }
    if (session is! AuthAuthenticated) {
      throw const AuthException.unauthorized();
    }
    // The in-memory default returns the held session without rotation. The
    // real adapter (and the test server) rotate the refresh token; the caller
    // persists whichever token the response carries, so the contract holds.
    return held;
  }

  @override
  Future<AuthSession> logout(AuthSession session) async {
    final held = _session;
    if (held is! AuthAuthenticated) {
      throw const AuthException.notConnected();
    }
    _session = const AuthAnonymous();
    return const AuthAnonymous();
  }
}
