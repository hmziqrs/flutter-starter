import 'dart:async';

// Initializing formals would expose private field names, so parameters stay explicit.
// ignore_for_file: prefer_initializing_formals

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

class FirebaseNotificationsRepository implements NotificationsRepository {
  FirebaseNotificationsRepository({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required AppLogger logger,
    required NotificationsRegistration registrationClient,
    required String platform,
    required String deviceId,
  }) : _messaging = messaging,
       _localNotifications = localNotifications,
       _logger = logger,
       _registrationClient = registrationClient,
       _platform = platform,
       _deviceId = deviceId;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final AppLogger _logger;
  final NotificationsRegistration _registrationClient;
  final String _platform;
  final String _deviceId;

  static const int _foregroundNotificationId = 0xb19e;

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'starter_notifications',
    'Starter notifications',
    description: 'Foreground push notifications rendered while the app is open.',
    importance: Importance.high,
  );

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required bool provisional,
  }) async {
    try {
      final settings = await _messaging.requestPermission(provisional: provisional);
      return _mapAuthorizationStatus(settings.authorizationStatus);
    } on Object catch (error, stackTrace) {
      _logger.error(
        'notifications.requestPermission failed',
        error: error,
        stackTrace: stackTrace,
      );
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<String?> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        return null;
      }
      await _registrationClient.registerToken(
        token: token,
        platform: _platform,
        deviceId: _deviceId,
      );
      _logger.debug(
        'notifications.registerToken',
        context: <String, Object?>{'platform': _platform, 'tokenLength': token.length},
      );
      return token;
    } on NotificationsException {
      rethrow;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'notifications.registerToken failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const NotificationsException.notConnected();
    }
  }

  @override
  Future<void> unregisterToken(String token) async {
    try {
      await _registrationClient.unregisterToken(token);
      await _messaging.deleteToken();
    } on NotificationsException {
      rethrow;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'notifications.unregisterToken failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const NotificationsException.notConnected();
    }
  }

  @override
  Stream<NotificationMessage> get onMessage {
    return FirebaseMessaging.onMessage.map(_toMessage).where((message) {
      unawaited(_renderForeground(message));
      return true;
    });
  }

  @override
  Stream<NotificationTap> get onNotificationTap {
    // onMessageOpenedApp misses cold-start taps, so getInitialMessage is merged in.
    final controller = StreamController<NotificationTap>.broadcast();
    unawaited(_wireInitialMessage(controller));
    FirebaseMessaging.onMessageOpenedApp
        .map(_toTap)
        .listen(controller.add, onError: controller.addError, onDone: controller.close);
    return controller.stream;
  }

  Future<void> _wireInitialMessage(StreamController<NotificationTap> controller) async {
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null && !controller.isClosed) {
        controller.add(_toTap(initial));
      }
    } on Object catch (error, stackTrace) {
      _logger.error(
        'notifications.getInitialMessage failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  NotificationMessage _toMessage(RemoteMessage message) {
    final notification = message.notification;
    return NotificationMessage(
      title: notification?.title,
      body: notification?.body,
      data: _stringifyData(message.data),
    );
  }

  NotificationTap _toTap(RemoteMessage message) {
    final target = message.data['target'];
    return NotificationTap(
      targetRoute: target is String && target.isNotEmpty ? target : AppNotificationRoute.home,
      params: _stringifyData(message.data),
    );
  }

  Future<void> _renderForeground(NotificationMessage message) async {
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
      await _localNotifications.show(
        _foregroundNotificationId,
        message.title,
        message.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      _logger.error(
        'notifications.foreground render failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static NotificationPermissionStatus _mapAuthorizationStatus(
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized => NotificationPermissionStatus.granted,
      AuthorizationStatus.provisional => NotificationPermissionStatus.provisional,
      AuthorizationStatus.denied => NotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined => NotificationPermissionStatus.notRequested,
    };
  }

  static Map<String, String> _stringifyData(Map<String, dynamic> data) {
    return {for (final entry in data.entries) entry.key: '${entry.value}'};
  }
}

@immutable
final class AppNotificationRoute {
  const AppNotificationRoute._();

  static const home = 'home';
}
