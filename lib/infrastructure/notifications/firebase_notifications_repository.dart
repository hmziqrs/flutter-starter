import 'dart:async';

// Private-field constructors with public-named required parameters are
// intentional: the constructor is the public surface (composition-root
// override) while the fields stay internal. `prefer_initializing_formals`
// would force `this._x` formals, which expose the private name as a named
// parameter — illegal for a public constructor.
// ignore_for_file: prefer_initializing_formals

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

/// Optional real [NotificationsRepository] backed by `firebase_messaging`
/// (FCM / APNs delivery) and `flutter_local_notifications` (foreground banner
/// rendering).
///
/// **Never constructed by default.** A consumer overrides
/// [notificationsRepositoryProvider] with this adapter only after wiring
/// Firebase credentials (`GoogleService-Info.plist` / `google-services.json`)
/// AND ensuring `Firebase.initializeApp` has run (in `bootstrap.dart`'s
/// `createApplication`, guarded by the `notifications` configuration flag).
/// `AppDependencies.production` constructs the `NoopNotificationsRepository`
/// for every other path (no credentials, web / desktop, or unset flag) so the
/// app runs green with zero backend (C2). No widget calls either plugin
/// directly — every side effect goes through this typed port.
///
/// The token-registration / permission-revoked round-trip is delegated to the
/// `registrationClient` constructor parameter (a thin HTTP adapter against the
/// test-server contract, C9). Message delivery cannot be mocked by a plain
/// HTTP server, so the foreground / tap paths wrap the plugin SDKs directly.
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

  /// Local-notification id used for foreground FCM renders. A stable id means a
  /// subsequent foreground message replaces the previous banner rather than
  /// stacking; consumers wanting a per-message stack can extend this with a
  /// hash of the message id.
  static const int _foregroundNotificationId = 0xb19e;

  // Channel id / name for Android foreground notification rendering. The
  // channel is created on first use; the values are stable across launches so
  // the OS group is consistent.
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
      final settings = await _messaging.requestPermission(
        // alert / badge / sound default to `true` in firebase_messaging; the
        // explicit `provisional` toggle below is the only non-default.
        provisional: provisional,
      );
      return _mapAuthorizationStatus(settings.authorizationStatus);
    } on Object catch (error, stackTrace) {
      // Degrade honestly: never fake a granted permission. A plugin failure
      // reads as `denied` so the rationale sheet shows the disabled copy.
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
      // Render foreground messages as visible local notifications. A failure
      // here never breaks the message stream — the typed value still flows to
      // any in-app banner consumer.
      unawaited(_renderForeground(message));
      return true;
    });
  }

  @override
  Stream<NotificationTap> get onNotificationTap {
    // Fold the cold-start initial message with the foreground / background
    // tap stream so the consumer observes taps in arrival order regardless of
    // process state. The controller's tap queue subscribes immediately on
    // build so neither the cold-start tap nor the first foreground tap is
    // lost.
    final controller = StreamController<NotificationTap>.broadcast();
    // Fire-and-forget: the initial-message future feeds the controller as soon
    // as it resolves; the foreground tap stream below feeds it in real time.
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
      // Channel registration is idempotent on Android; a no-op elsewhere.
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
      // Foreground rendering is best-effort. A failure must never break the
      // foreground message stream above — the typed value still flows to any
      // in-app banner consumer.
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

/// Route constants a push payload may target. Kept feature-local — the
/// notifications port resolves taps to **existing** named routes via the
/// router; this is just the typed fallback when a payload omits a target.
@immutable
final class AppNotificationRoute {
  const AppNotificationRoute._();

  static const home = 'home';
}
