import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';

enum NotificationsFailureKind {
  notConnected,

  denied,

  unknown,
}

final class NotificationsException implements Exception {
  const NotificationsException.notConnected()
    : kind = NotificationsFailureKind.notConnected,
      cause = null;

  const NotificationsException.denied([this.cause]) : kind = NotificationsFailureKind.denied;

  const NotificationsException.unknown([this.cause]) : kind = NotificationsFailureKind.unknown;

  final NotificationsFailureKind kind;

  final Object? cause;

  @override
  String toString() => 'NotificationsException(${kind.name})';
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
