import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/noop_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

void main() {
  group('NoopNotificationsRepository', () {
    test('requestPermission returns denied (honest, never granted)', () async {
      const repo = NoopNotificationsRepository();
      final status = await repo.requestPermission(provisional: false);
      expect(status, NotificationPermissionStatus.denied);
    });

    test('requestPermission with provisional still returns denied', () async {
      const repo = NoopNotificationsRepository();
      final status = await repo.requestPermission(provisional: true);
      expect(status, NotificationPermissionStatus.denied);
    });

    test('registerToken surfaces notConnected (never fakes a token)', () async {
      const repo = NoopNotificationsRepository();
      await expectLater(
        repo.registerToken(),
        throwsA(
          isA<NotificationsException>().having(
            (e) => e.kind,
            'kind',
            NotificationsFailureKind.notConnected,
          ),
        ),
      );
    });

    test('unregisterToken surfaces notConnected', () async {
      const repo = NoopNotificationsRepository();
      await expectLater(
        repo.unregisterToken('anything'),
        throwsA(
          isA<NotificationsException>().having(
            (e) => e.kind,
            'kind',
            NotificationsFailureKind.notConnected,
          ),
        ),
      );
    });

    test('onMessage emits nothing and completes', () async {
      const repo = NoopNotificationsRepository();
      await expectLater(repo.onMessage.isEmpty, completion(true));
    });

    test('onNotificationTap emits nothing and completes', () async {
      const repo = NoopNotificationsRepository();
      await expectLater(repo.onNotificationTap.isEmpty, completion(true));
    });
  });
}
