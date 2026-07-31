import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';

final class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthSession? seed}) : _session = seed;

  AuthSession? _session;

  AuthSession get current => _session ?? const AuthAnonymous();

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    final session = _session;
    if (session is! AuthAuthenticated) {
      throw const AuthException.notConnected();
    }
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
