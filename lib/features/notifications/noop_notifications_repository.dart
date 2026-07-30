import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Production default [NotificationsRepository]: reports
/// [NotificationPermissionStatus.denied] for permission requests, publishes
/// empty foreground / tap streams, and throws
/// [NotificationsException.notConnected] for the token-registration actions.
/// Never fakes a granted token or a delivered message.
///
/// Constructed in `AppDependencies.production`. The optional real Firebase
/// adapter overrides the provider only when the consumer wires Firebase
/// credentials. Selected for desktop / web via `PlatformCapabilities`
/// (`firebase_messaging` has no desktop / web support).
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
