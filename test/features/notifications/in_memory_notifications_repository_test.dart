import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/in_memory_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

void main() {
  group('InMemoryNotificationsRepository', () {
    group('requestPermission state machine', () {
      test('notRequested -> granted on default (non-provisional) request', () async {
        final repo = InMemoryNotificationsRepository();
        final status = await repo.requestPermission(provisional: false);
        expect(status, NotificationPermissionStatus.granted);
        expect(repo.permission, NotificationPermissionStatus.granted);
      });

      test('notRequested -> provisional when provisional=true', () async {
        final repo = InMemoryNotificationsRepository();
        final status = await repo.requestPermission(provisional: true);
        expect(status, NotificationPermissionStatus.provisional);
        expect(repo.permission, NotificationPermissionStatus.provisional);
      });

      test('seeded denied stays denied (no surprise prompt)', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.denied,
        );
        final status = await repo.requestPermission(provisional: false);
        expect(status, NotificationPermissionStatus.denied);
      });

      test('permission setter knob bypasses the state machine', () {
        final repo = InMemoryNotificationsRepository()
          ..permission = NotificationPermissionStatus.provisional;
        expect(repo.permission, NotificationPermissionStatus.provisional);
      });
    });

    group('registerToken', () {
      test('mints a token after permission is granted', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
        );
        final token = await repo.registerToken();
        expect(token, isNotNull);
        expect(repo.token, token);
      });

      test('reuses a seeded token instead of minting a new one', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
          token: 'seeded-token',
        );
        expect(await repo.registerToken(), 'seeded-token');
      });

      test('surfaces denied when permission was not granted', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.denied,
        );
        await expectLater(
          repo.registerToken(),
          throwsA(
            isA<NotificationsException>().having(
              (e) => e.kind,
              'kind',
              NotificationsFailureKind.denied,
            ),
          ),
        );
      });

      test('provisional authorization is sufficient to register', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.provisional,
        );
        expect(await repo.registerToken(), isNotNull);
      });
    });

    group('unregisterToken', () {
      test('clears the token when it matches', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
          token: 'seeded-token',
        );
        await repo.unregisterToken('seeded-token');
        expect(repo.token, isNull);
      });

      test('leaves a mismatched token alone (idempotent best-effort)', () async {
        final repo = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
          token: 'seeded-token',
        );
        await repo.unregisterToken('other');
        expect(repo.token, 'seeded-token');
      });
    });

    group('streams', () {
      test('deliverMessage publishes to onMessage', () async {
        final repo = InMemoryNotificationsRepository();
        final messages = <NotificationMessage>[];
        final subscription = repo.onMessage.listen(messages.add);
        const msg = NotificationMessage(title: 't', body: 'b');
        repo.deliverMessage(msg);
        await Future<void>.delayed(Duration.zero);
        expect(messages, [msg]);
        await subscription.cancel();
      });

      test('deliverTap publishes to onNotificationTap', () async {
        final repo = InMemoryNotificationsRepository();
        final taps = <NotificationTap>[];
        final subscription = repo.onNotificationTap.listen(taps.add);
        const tap = NotificationTap(targetRoute: 'home');
        repo.deliverTap(tap);
        await Future<void>.delayed(Duration.zero);
        expect(taps, [tap]);
        await subscription.cancel();
      });

      test('dispose closes the controllers', () async {
        final repo = InMemoryNotificationsRepository()..dispose();
        await expectLater(repo.onMessage.isEmpty, completion(true));
        await expectLater(repo.onNotificationTap.isEmpty, completion(true));
      });
    });
  });
}
