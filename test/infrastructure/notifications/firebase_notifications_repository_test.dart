import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/notifications/firebase_notifications_repository.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupFirebaseCoreMocks);

  setUp(() {
    // The foreground renderer drives the Android plugin surface; make the
    // target platform deterministic instead of the host's default.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(_resetTargetPlatform);
  });

  test('a foreground message is rendered through flutter_local_notifications', () async {
    await Firebase.initializeApp();
    final localNotifications = _RecordingAndroidLocalNotifications();
    FlutterLocalNotificationsPlatform.instance = localNotifications;

    final repository = FirebaseNotificationsRepository(
      messaging: FirebaseMessaging.instance,
      localNotifications: FlutterLocalNotificationsPlugin(),
      logger: AppLogger.bootstrap(),
      registrationClient: const _NoopRegistration(),
      platform: 'android',
      deviceId: 'test-device',
    );

    final delivered = <NotificationMessage>[];
    final subscription = repository.onMessage.listen(delivered.add);
    addTearDown(subscription.cancel);

    FirebaseMessagingPlatform.onMessage.add(
      const RemoteMessage(
        data: <String, dynamic>{'target': 'home'},
        notification: RemoteNotification(title: 'Foreground title', body: 'Foreground body'),
      ),
    );
    for (var attempt = 0; attempt < 4; attempt += 1) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(delivered, hasLength(1), reason: 'the mapped message still reaches listeners');
    expect(delivered.single.title, 'Foreground title');
    expect(delivered.single.body, 'Foreground body');

    expect(localNotifications.createdChannels, hasLength(1));
    expect(localNotifications.createdChannels.single.id, 'starter_notifications');
    final shown = localNotifications.shown.single;
    expect(shown.id, 0xb19e);
    expect(shown.title, 'Foreground title');
    expect(shown.body, 'Foreground body');
    expect(shown.details?.channelId, 'starter_notifications');
    expect(shown.details?.priority, Priority.high);
  });
}

void _resetTargetPlatform() {
  debugDefaultTargetPlatformOverride = null;
}

final class _NoopRegistration implements NotificationsRegistration {
  const _NoopRegistration();

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
    required String deviceId,
  }) async {}

  @override
  Future<void> unregisterToken(String token) async {}

  @override
  Future<void> reportPermissionRevoked({required String deviceId}) async {}
}

final class _RecordingAndroidLocalNotifications extends AndroidFlutterLocalNotificationsPlugin {
  final createdChannels = <AndroidNotificationChannel>[];
  final shown = <({int id, String? title, String? body, AndroidNotificationDetails? details})>[];

  @override
  Future<void> createNotificationChannel(AndroidNotificationChannel notificationChannel) async =>
      createdChannels.add(notificationChannel);

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add((id: id, title: title, body: body, details: notificationDetails));
  }
}
