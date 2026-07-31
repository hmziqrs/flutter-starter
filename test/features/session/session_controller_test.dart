import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/in_memory_auth_repository.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/session/session_repository.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

void main() {
  group('SessionController.login', () {
    test('optimistically authenticates and persists only the refresh token', () async {
      final store = InMemorySecureStore();
      final repository = InMemoryAuthRepository(
        seed: AuthAuthenticated(
          accessToken: 'at-secret',
          refreshToken: 'rt-secret',
          expiresAt: DateTime.utc(2030),
          userId: 'user-1',
        ),
      );
      final container = _buildContainer(
        store: store,
        repository: repository,
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);
      await controller.login(const AuthCredentials(email: 'a@b.c', password: 'pw'));

      final state = container.read(sessionControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).accessToken, 'at-secret');

      expect(await store.read(SessionRepository.refreshTokenKey), 'rt-secret');
      expect(
        store.snapshot.values,
        isNot(contains('at-secret')),
        reason: 'Access token must never touch the persistent store.',
      );
    });

    test('rolls back when refresh-token persistence fails', () async {
      final store = InMemorySecureStore()..failWrites = true;
      final repository = InMemoryAuthRepository(
        seed: AuthAuthenticated(
          accessToken: 'at',
          refreshToken: 'rt',
          expiresAt: DateTime.utc(2030),
          userId: 'user-1',
        ),
      );
      final container = _buildContainer(store: store, repository: repository);
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);

      await expectLater(
        controller.login(const AuthCredentials(email: 'a@b.c', password: 'pw')),
        throwsA(isA<SecureStoreException>()),
      );
      expect(container.read(sessionControllerProvider), const AuthAnonymous());
    });

    test('propagates AuthException and leaves state anonymous when unseeded', () async {
      final store = InMemorySecureStore();
      final repository = InMemoryAuthRepository();
      final container = _buildContainer(store: store, repository: repository);
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);

      await expectLater(
        controller.login(const AuthCredentials(email: 'a@b.c', password: 'pw')),
        throwsA(isA<AuthException>()),
      );
      expect(container.read(sessionControllerProvider), const AuthAnonymous());
      expect(store.snapshot, isEmpty);
    });
  });

  group('SessionController.refresh', () {
    test('rotates the session and persists the new refresh token', () async {
      final store = InMemorySecureStore(seed: {SessionRepository.refreshTokenKey: 'rt-old'});
      final seed = AuthAuthenticated(
        accessToken: 'at',
        refreshToken: 'rt-old',
        expiresAt: DateTime.utc(2030),
        userId: 'user-1',
      );
      final repository = InMemoryAuthRepository(seed: seed);
      final container = _buildContainer(
        store: store,
        repository: repository,
        initialSession: seed,
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);
      await controller.refresh();

      final state = container.read(sessionControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect(
        await store.read(SessionRepository.refreshTokenKey),
        (state as AuthAuthenticated).refreshToken,
      );
    });
  });

  group('SessionController.logout', () {
    test('clears state, best-effort server invalidation, and removes the token', () async {
      final store = InMemorySecureStore(seed: {SessionRepository.refreshTokenKey: 'rt'});
      final seed = AuthAuthenticated(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.utc(2030),
        userId: 'user-1',
      );
      final repository = InMemoryAuthRepository(seed: seed);
      final container = _buildContainer(
        store: store,
        repository: repository,
        initialSession: seed,
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);
      await controller.logout();

      expect(container.read(sessionControllerProvider), const AuthAnonymous());
      expect(await store.read(SessionRepository.refreshTokenKey), isNull);
      expect(repository.current, const AuthAnonymous());
    });

    test('still clears local state when the backend rejects logout', () async {
      final store = InMemorySecureStore(seed: {SessionRepository.refreshTokenKey: 'rt'});
      final seed = AuthAuthenticated(
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.utc(2030),
        userId: 'user-1',
      );
      final repository = InMemoryAuthRepository();
      final container = _buildContainer(
        store: store,
        repository: repository,
        initialSession: seed,
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionControllerProvider.notifier);
      await controller.logout();

      expect(container.read(sessionControllerProvider), const AuthAnonymous());
      expect(await store.read(SessionRepository.refreshTokenKey), isNull);
    });
  });

  group('SessionController.hydrateFromSecureStore', () {
    test('no-ops when no refresh token is persisted', () async {
      final store = InMemorySecureStore();
      final repository = InMemoryAuthRepository();
      final container = _buildContainer(store: store, repository: repository);
      addTearDown(container.dispose);

      await container.read(sessionControllerProvider.notifier).hydrateFromSecureStore();

      expect(container.read(sessionControllerProvider), const AuthAnonymous());
    });

    test('drops the stale token and stays anonymous when no backend is wired', () async {
      final store = InMemorySecureStore(seed: {SessionRepository.refreshTokenKey: 'rt-stale'});
      final repository = InMemoryAuthRepository();
      final container = _buildContainer(store: store, repository: repository);
      addTearDown(container.dispose);

      await container.read(sessionControllerProvider.notifier).hydrateFromSecureStore();

      expect(container.read(sessionControllerProvider), const AuthAnonymous());
      expect(await store.read(SessionRepository.refreshTokenKey), isNull);
    });
  });
}

ProviderContainer _buildContainer({
  required InMemorySecureStore store,
  required InMemoryAuthRepository repository,
  AuthSession initialSession = const AuthAnonymous(),
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      sessionRepositoryProvider.overrideWithValue(SessionRepository(store)),
      initialSessionProvider.overrideWithValue(initialSession),
    ],
  );
}
