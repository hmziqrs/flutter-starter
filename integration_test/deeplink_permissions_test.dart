import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';

import 'integration_test_support.dart';

const _allowedHosts = AllowedDeepLinkHosts({'link.starter.dev'});

const _fixtureAvatar = PickedMedia(
  path: '/fixtures/avatar.png',
  mimeType: 'image/png',
  fromCamera: false,
);

final class _GrantedPermissionService implements PermissionService {
  const _GrantedPermissionService();

  @override
  Future<PermissionStatus> checkStatus(AppPermission permission) async => const PermissionGranted();

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async =>
      const PermissionGranted();

  @override
  Future<void> openSystemSettings() async {}
}

final class _FixtureMediaPicker implements MediaPicker {
  const _FixtureMediaPicker(this.media);

  final PickedMedia media;

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async => media;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('streamed deep links dispatch and the granted avatar flow picks end-to-end', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);

    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await LocaleSettings.setLocale(AppLocale.en);

    final controller = StreamController<Uri>.broadcast();
    addTearDown(controller.close);
    await tester.pumpWidget(
      App(
        config: config,
        dependencies: AppDependencies.inMemory(
          appLinkHandler: StreamDeepLinkService(
            handler: const RouteAppLinkHandler(allowedHosts: _allowedHosts),
            controller: controller,
          ),
          permissionService: const _GrantedPermissionService(),
          mediaPicker: const _FixtureMediaPicker(_fixtureAvatar),
        ),
        initialLocation: AppRoutes.homePath,
      ),
    );
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    controller.add(Uri.parse('https://link.starter.dev${AppRoutes.pricingPath}'));
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

    // Granted permission + fake picker, wired end-to-end through the profile route.
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('pricing-page'))),
      listen: false,
    );
    await container
        .read(sessionControllerProvider.notifier)
        .establish(
          AuthAuthenticated(
            accessToken: 'deeplink-access-token',
            refreshToken: 'deeplink-refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            userId: 'deeplink-user',
          ),
        );
    await pumpAppFrames(tester);
    await _go(tester, AppRoutes.updateProfilePath);
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);

    for (var i = 0; i < 8; i += 1) {
      final announcementDismiss = find.byKey(const ValueKey('announcement-dismiss'));
      if (announcementDismiss.evaluate().isEmpty) {
        break;
      }
      await tester.tap(announcementDismiss.hitTestable());
      await pumpAppFrames(tester);
    }

    await tapVisible(tester, const ValueKey('profile-avatar-feedback'));
    expect(find.text('Photo library access'), findsOneWidget);
    await tester.tap(find.text('Continue').hitTestable());
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('profile-avatar-image')), findsOneWidget);
    expect(find.byKey(const ValueKey('information-dialog')), findsNothing);
  });
}

Future<void> _go(WidgetTester tester, String location) async {
  final rootContext = tester.element(find.byType(Navigator).first);
  GoRouter.of(rootContext).go(location);
  await pumpAppFrames(tester);
}
