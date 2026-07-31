import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Production default; selected for desktop/web because `firebase_messaging` has no support there.
final class NoopNotificationsRepository implements NotificationsRepository {
  const NoopNotificationsRepository();

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required bool provisional,
  }) async => NotificationPermissionStatus.denied;

  @override
  Future<String?> registerToken() async => throw const NotificationsException.notConnected();

  @override
  Future<void> unregisterToken(String token) async =>
      throw const NotificationsException.notConnected();

  @override
  Stream<NotificationMessage> get onMessage => const Stream<NotificationMessage>.empty();

  @override
  Stream<NotificationTap> get onNotificationTap => const Stream<NotificationTap>.empty();
}
