import 'dart:async';

// ignore_for_file: prefer_initializing_formals, initializer list assigns to public fields

import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

final class InMemoryNotificationsRepository implements NotificationsRepository {
  InMemoryNotificationsRepository({
    NotificationPermissionStatus permission = NotificationPermissionStatus.notRequested,
    String? token,
  }) : permission = permission,
       token = token;

  NotificationPermissionStatus permission;

  String? token;

  final StreamController<NotificationMessage> _messages =
      StreamController<NotificationMessage>.broadcast();
  final StreamController<NotificationTap> _taps = StreamController<NotificationTap>.broadcast();

  void deliverMessage(NotificationMessage message) {
    _messages.add(message);
  }

  void deliverTap(NotificationTap tap) {
    _taps.add(tap);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required bool provisional,
  }) async {
    if (permission == NotificationPermissionStatus.notRequested) {
      permission = provisional
          ? NotificationPermissionStatus.provisional
          : NotificationPermissionStatus.granted;
    }
    return permission;
  }

  @override
  Future<String?> registerToken() async {
    if (!permission.canDeliver) {
      throw const NotificationsException.denied();
    }
    return token ??= 'in-memory-token-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> unregisterToken(String token) async {
    if (this.token == token) {
      this.token = null;
    }
  }

  @override
  Stream<NotificationMessage> get onMessage => _messages.stream;

  @override
  Stream<NotificationTap> get onNotificationTap => _taps.stream;

  void dispose() {
    unawaited(_messages.close());
    unawaited(_taps.close());
  }
}
