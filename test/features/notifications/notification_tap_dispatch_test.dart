import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/dependencies/dependency_aggregates.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/notifications/in_memory_notifications_repository.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/i18n/translations.g.dart';

import '../../app/support/pump_app_frames.dart';

void main() {
  testWidgets('a notification tap pushes the target named route and drains the queue', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.en);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = InMemoryNotificationsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: _dependenciesWithNotifications(repository),
      ),
    );
    // The router drain installs itself in a post-frame callback after mount.
    await pumpAppFrames(tester);

    repository.deliverTap(const NotificationTap(targetRoute: AppRoutes.settings));
    await pumpAppFrames(tester);

    final settingsContext = tester.element(find.byType(SettingsPage));
    expect(
      GoRouterState.of(settingsContext).uri.path,
      AppRoutes.settingsPath,
      reason: 'the tap must land on the named target route, not a raw URI',
    );
    expect(
      GoRouter.of(settingsContext).canPop(),
      isTrue,
      reason: 'taps push on top of the running surface',
    );
    expect(
      ProviderScope.containerOf(settingsContext).read(notificationTapQueueProvider),
      isEmpty,
      reason: 'a dispatched tap is consumed so it cannot dispatch twice',
    );
  });
}

AppDependencies _dependenciesWithNotifications(InMemoryNotificationsRepository repository) {
  // copyWith cannot swap the notifications bundle; rebuild the in-memory graph
  // around a repository the test can drive.
  final base = AppDependencies.inMemory();
  return AppDependencies(
    logger: base.logger,
    settings: base.settings,
    storage: base.storage,
    auth: base.auth,
    telemetry: base.telemetry,
    remoteConfig: base.remoteConfig,
    notifications: NotificationDependencies(
      notificationsRepository: repository,
      notificationsBackend: base.notifications.notificationsBackend,
      initialNotificationPermission: base.notifications.initialNotificationPermission,
      initialNotificationToken: base.notifications.initialNotificationToken,
    ),
    feedback: base.feedback,
    platform: base.platform,
    appStartupResult: base.appStartupResult,
    initialDismissedAnnouncementIds: base.initialDismissedAnnouncementIds,
    inspectorHost: base.inspectorHost,
  );
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
