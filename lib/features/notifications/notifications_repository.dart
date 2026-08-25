import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/shared/errors/repository_exception.dart';

enum NotificationsFailureKind {
  notConnected,

  denied,

  unknown,
}

final class NotificationsException extends RepositoryException<NotificationsFailureKind> {
  const NotificationsException.notConnected() : super(kind: NotificationsFailureKind.notConnected);

  const NotificationsException.denied([Object? cause])
    : super(kind: NotificationsFailureKind.denied, cause: cause);

  const NotificationsException.unknown([Object? cause])
    : super(kind: NotificationsFailureKind.unknown, cause: cause);

  @override
  String toString() => describe('NotificationsException');
}

sealed class NotificationsBackend {
  const NotificationsBackend();
}

final class NoopNotificationsBackend extends NotificationsBackend {
  const NoopNotificationsBackend();
}

final class RemoteNotificationsBackend extends NotificationsBackend {
  const RemoteNotificationsBackend({required this.registrationHost});

  final String registrationHost;
}

abstract interface class NotificationsRepository {
  Future<NotificationPermissionStatus> requestPermission({required bool provisional});

  Future<String?> registerToken();

  Future<void> unregisterToken(String token);

  Stream<NotificationMessage> get onMessage;

  Stream<NotificationTap> get onNotificationTap;
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw StateError(
    'NotificationsRepository must be overridden at the composition root.',
  ),
);

final notificationsBackendProvider = Provider<NotificationsBackend>(
  (ref) => const NoopNotificationsBackend(),
);
