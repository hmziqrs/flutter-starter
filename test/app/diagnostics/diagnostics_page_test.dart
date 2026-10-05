import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';

import '../support/pump_app_frames.dart';

/// `/dev/diagnostics` share + update dev-trigger coverage, headless on the
/// flutter tester. The second case reuses `createApplication` like the desktop
/// smoke flow (harness shape of `test/app/routing/deep_link_wiring_test.dart`);
/// both must surface the honest noop outcomes — never a faked success.
final _config = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

Finder _shareTrigger() => find.byKey(const ValueKey('diagnostics-share-trigger'));

Finder _updateTrigger() => find.byKey(const ValueKey('diagnostics-update-check'));

void main() {
  testWidgets('createApplication composition drives both triggers to honest outcomes', (
    tester,
  ) async {
    final previousPrefs = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previousPrefs);
    PackageInfo.setMockInitialValues(
      appName: 'starter',
      packageName: 'starter',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    _setViewport(tester, const Size(390, 844));
    await SharedPreferencesSettingsStore().writeString(
      SettingsRepository.onboardingKey,
      'true',
    );
    final links = StreamController<Uri>.broadcast();
    addTearDown(links.close);

    // The tester self-reports as android, which would select the SharePlus and
    // Play adapters whose platform channels cannot settle inside a fake-async
    // widget test; pin the desktop platform so the composition picks the honest
    // noop adapters. Restored in `finally` because the binding verifies
    // foundation debug variables before teardown callbacks run.
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      // createApplication awaits real platform probes (capabilities, cache
      // directory), so it runs through runAsync instead of fake async.
      final app = await tester.runAsync(
        () => createApplication(
          _config,
          secureStore: InMemorySecureStore(),
          connectivityService: const StaticConnectivityService(),
          appLinkHandler: StreamDeepLinkService(
            handler: const RouteAppLinkHandler(allowedHosts: AllowedDeepLinkHosts.empty),
            controller: links,
          ),
        ),
      );
      await tester.pumpWidget(app!);
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

      final translations = _expectTriggersIdle(tester);
      await _runTriggersExpectingNoopOutcomes(tester, translations);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}

/// Asserts both dev triggers render in their idle state and returns the active
/// translations for the outcome expectations.
Translations _expectTriggersIdle(WidgetTester tester) {
  expect(_shareTrigger(), findsOneWidget);
  expect(_updateTrigger(), findsOneWidget);
  final translations = tester.element(_shareTrigger()).t;
  expect(find.text(translations.diagnostics.triggerIdle), findsNWidgets(2));
  return translations;
}

/// Presses both trigger tiles (bounded frames) and expects the honest noop
/// outcomes from the adapters selected for a desktop composition.
Future<void> _runTriggersExpectingNoopOutcomes(WidgetTester tester, Translations t) async {
  await _tapTrigger(tester, _shareTrigger());
  expect(find.text(t.share.unavailable), findsOneWidget);
  await _tapTrigger(tester, _updateTrigger());
  expect(find.text(t.update.notAvailable), findsOneWidget);
}

/// Scrolls a trigger tile into view and presses it with bounded frames (the
/// tiles live far down the diagnostics list).
Future<void> _tapTrigger(WidgetTester tester, Finder trigger) async {
  await tester.ensureVisible(trigger);
  await pumpAppFrames(tester);
  await tester.tap(trigger.hitTestable());
  await pumpAppFrames(tester);
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
