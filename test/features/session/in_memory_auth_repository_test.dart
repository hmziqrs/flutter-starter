import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/in_memory_auth_repository.dart';

void main() {
  group('InMemoryAuthRepository', () {
    group('when unseeded (no-backend default)', () {
      test('login surfaces AuthException.notConnected', () async {
        final repository = InMemoryAuthRepository();
        await expectLater(
          repository.login(const AuthCredentials(email: 'a@b.c', password: 'pw')),
          throwsA(
            isA<AuthException>().having((e) => e.kind, 'kind', AuthFailureKind.notConnected),
          ),
        );
      });

      test('refresh surfaces AuthException.notConnected', () async {
        final repository = InMemoryAuthRepository();
        await expectLater(
          repository.refresh(
            AuthAuthenticated(
              accessToken: 'at',
              refreshToken: 'rt',
              expiresAt: DateTime.utc(2030),
              userId: 'u',
            ),
          ),
          throwsA(
            isA<AuthException>().having((e) => e.kind, 'kind', AuthFailureKind.notConnected),
          ),
        );
      });

      test('logout surfaces AuthException.notConnected', () async {
        final repository = InMemoryAuthRepository();
        await expectLater(
          repository.logout(
            AuthAuthenticated(
              accessToken: 'at',
              refreshToken: 'rt',
              expiresAt: DateTime.utc(2030),
              userId: 'u',
            ),
          ),
          throwsA(
            isA<AuthException>().having((e) => e.kind, 'kind', AuthFailureKind.notConnected),
          ),
        );
      });

      test('never fakes a session: current is anonymous', () async {
        expect(InMemoryAuthRepository().current, const AuthAnonymous());
      });
    });

    group('when seeded with an authenticated session', () {
      late AuthAuthenticated seed;
      late InMemoryAuthRepository repository;

      setUp(() {
        seed = AuthAuthenticated(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: DateTime.utc(2030),
          userId: 'user-1',
        );
        repository = InMemoryAuthRepository(seed: seed);
      });

      test('login returns the held session regardless of credentials', () async {
        final result = await repository.login(
          const AuthCredentials(email: 'a@b.c', password: 'pw'),
        );
        expect(result, seed);
      });

      test('refresh returns the held session (rotation is the real adapter)', () async {
        final result = await repository.refresh(seed);
        expect(result, seed);
      });

      test('refresh rejects an anonymous session with unauthorized', () async {
        await expectLater(
          repository.refresh(const AuthAnonymous()),
          throwsA(
            isA<AuthException>().having((e) => e.kind, 'kind', AuthFailureKind.unauthorized),
          ),
        );
      });

      test('logout returns anonymous and clears the held session', () async {
        final result = await repository.logout(seed);
        expect(result, const AuthAnonymous());
        expect(repository.current, const AuthAnonymous());
      });
    });
  });
}
