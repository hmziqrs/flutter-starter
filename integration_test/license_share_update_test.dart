import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';

import 'integration_test_support.dart';

/// License / share / update dev-trigger coverage on `/dev/diagnostics`, run on
/// a real device through the full `createApplication` composition. The smoke
/// target (macOS) has no share target and no OS store, so the honest noop
/// adapters must report `unavailable` / `noUpdate` — never a faked success;
/// platforms with a native sheet or store skip those taps with a logged reason.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('diagnostics share + update dev triggers report honest outcomes', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);
    expect(config.developmentToolsEnabled, isTrue);

    await resetTestSettings();
    addTearDown(resetTestSettings);
    tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      await createApplication(
        config,
        secureStore: InMemorySecureStore(),
        connectivityService: const StaticConnectivityService(),
      ),
    );
    await pumpAppFrames(tester);

    for (var i = 0; i < 8; i += 1) {
      final announcementDismiss = find.byKey(const ValueKey('announcement-dismiss'));
      if (announcementDismiss.evaluate().isEmpty) {
        break;
      }
      await tester.tap(announcementDismiss.hitTestable());
      await pumpAppFrames(tester);
    }

    GoRouter.of(tester.element(find.byType(Navigator).first)).go(AppRoutes.diagnosticsPath);
    await pumpAppFrames(tester);

    final shareTrigger = find.byKey(const ValueKey('diagnostics-share-trigger'));
    final updateTrigger = find.byKey(const ValueKey('diagnostics-update-check'));
    expect(shareTrigger, findsOneWidget, reason: 'share trigger must exist when dev tools are on');
    expect(
      updateTrigger,
      findsOneWidget,
      reason: 'update trigger must exist when dev tools are on',
    );
    final translations = tester.element(shareTrigger).t;
    expect(find.text(translations.diagnostics.triggerIdle), findsNWidgets(2));

    final capabilities = PlatformCapabilities.current();
    if (!shareTargetAvailable(capabilities)) {
      await tapVisible(tester, const ValueKey('diagnostics-share-trigger'));
      expect(find.text(translations.share.unavailable), findsOneWidget);
    } else {
      debugPrint('skipping share tap: the native share sheet is not headless-drivable');
    }

    final platform = capabilities.platform;
    if (platform != 'android' && platform != 'iOS') {
      await tapVisible(tester, const ValueKey('diagnostics-update-check'));
      expect(find.text(translations.update.notAvailable), findsOneWidget);
    } else {
      debugPrint('skipping update tap: the OS store update API is not headless-drivable');
    }
  });
}
