import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// In-memory [AuthRepository] for the no-backend production default and unit
/// tests. `login` / `refresh` / `logout` all surface `notConnected` when no
/// session has been seeded and never fake success. Tests seed a session to
/// drive the authenticated paths; production runs unseeded until a consumer
/// wires the optional real HTTP adapter.
final class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthSession? seed}) : _session = seed;

  AuthSession? _session;

  /// The currently held session (anonymous when nothing is seeded).
  AuthSession get current => _session ?? const AuthAnonymous();

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    final session = _session;
    if (session is! AuthAuthenticated) {
      throw const AuthException.notConnected();
    }
    // Returns the seeded session regardless of credentials; the real adapter
    // issues a fresh one, same contract (caller persists the refresh token).
    return session;
  }

  @override
  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  }) async {
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
    // Returns the held session without rotation; the real adapter rotates the
    // refresh token, same persistence contract.
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
