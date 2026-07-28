import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';

import 'tv_test_harness.dart';

final _authenticatedSession = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);

void main() {
  const routeAnchors = <({String location, String focusKey})>[
    (
      location: AppRoutes.onboardingPath,
      focusKey: 'onboarding-skip',
    ),
    (
      location: AppRoutes.onboardingPaywallPath,
      focusKey: 'paywall-skip',
    ),
    (
      location: AppRoutes.loginPath,
      focusKey: 'auth-login-email-activation',
    ),
    (
      location: AppRoutes.registerPath,
      focusKey: 'auth-register-display-name-activation',
    ),
    (
      location: AppRoutes.forgotPasswordPath,
      focusKey: 'auth-forgot-password-email-activation',
    ),
    (
      location: AppRoutes.resetPasswordPath,
      focusKey: 'auth-reset-password-new-activation',
    ),
    (
      location: '/auth/otp/registration',
      focusKey: 'auth-otp-code-activation',
    ),
    (
      location: AppRoutes.updateProfilePath,
      focusKey: 'profile-display-name-activation',
    ),
    (
      location: '/route-that-does-not-exist',
      focusKey: 'route-error-home',
    ),
  ];

  for (final route in routeAnchors) {
    testWidgets('${route.location} has an actionable TV cold-focus anchor', (
      tester,
    ) async {
      configureTvTestView(tester);
      await _pumpTvApp(
        tester,
        initialLocation: route.location,
        initialSession: route.location == AppRoutes.updateProfilePath
            ? _authenticatedSession
            : null,
      );

      expect(
        focusIsWithin(tester, route.focusKey),
        isTrue,
        reason: FocusManager.instance.primaryFocus?.toStringDeep(),
      );
      expectFocusedTargetInsideSafeFrame(tester, route.focusKey);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('information dialog focuses Close and restores its invoker', (
    tester,
  ) async {
    configureTvTestView(tester);
    await _pumpTvApp(tester, initialLocation: AppRoutes.pricingPath);

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpTvFrames(tester);
    expect(focusIsWithin(tester, 'billing-monthly'), isTrue);

    await requestFocusWithin(tester, 'select-plan-basic');
    expect(focusIsWithin(tester, 'select-plan-basic'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpTvFrames(tester);

    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    expect(focusIsWithin(tester, 'information-dialog-close'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpTvFrames(tester);
    expect(find.byKey(const ValueKey('information-dialog')), findsNothing);
    expect(focusIsWithin(tester, 'select-plan-basic'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system Back closes a dirty editor before opening discard', (
    tester,
  ) async {
    configureTvTestView(tester);
    await _pumpTvApp(
      tester,
      initialLocation: AppRoutes.updateProfilePath,
      initialSession: _authenticatedSession,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpTvFrames(tester, frames: 2);
    expect(focusIsWithin(tester, 'profile-display-name'), isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name')),
      'Changed on television',
    );
    await pumpTvFrames(tester, frames: 2);

    await _sendRemoteBack(tester);
    await pumpTvFrames(tester, frames: 2);
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsNothing);
    expect(focusIsWithin(tester, 'profile-display-name-activation'), isTrue);
    expect(
      ModalRoute.of(
        tester.element(
          find.byKey(const ValueKey('profile-display-name-activation')),
        ),
      )?.popDisposition,
      RoutePopDisposition.doNotPop,
    );

    await _sendRemoteBack(tester);
    await pumpTvFrames(tester);
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsOneWidget);
    expect(focusIsWithin(tester, 'profile-keep-editing'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP traversal never enters editing until Select', (
    tester,
  ) async {
    configureTvTestView(tester);
    await _pumpTvApp(
      tester,
      initialLocation: AppRoutes.otpLocation(OtpPurpose.registration),
    );

    expect(focusIsWithin(tester, 'auth-otp-code-activation'), isTrue);
    expect(find.byKey(const ValueKey('auth-otp-code')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpTvFrames(tester, frames: 2);
    expect(focusIsWithin(tester, 'auth-otp-code'), isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-code')),
      '12',
    );
    await pumpTvFrames(tester, frames: 2);

    await _sendRemoteBack(tester);
    await pumpTvFrames(tester, frames: 2);
    expect(focusIsWithin(tester, 'auth-otp-code-activation'), isTrue);
    expect(find.text('••••••••'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _sendRemoteBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
}

Future<void> _pumpTvApp(
  WidgetTester tester, {
  required String initialLocation,
  AuthSession? initialSession,
}) async {
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      dependencies: AppDependencies.inMemory(
        platformCapabilities: androidTvCapabilities,
        initialSession: initialSession,
      ),
      initialLocation: initialLocation,
    ),
  );
  await pumpTvFrames(tester);
}

bool focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }
  return _isWithin(focusContext, tester.element(find.byKey(ValueKey(key))));
}

Future<void> requestFocusWithin(WidgetTester tester, String key) async {
  final target = tester.element(find.byKey(ValueKey(key)));
  final candidates = FocusManager.instance.rootScope.descendants.where((node) {
    final context = node.context;
    return node.canRequestFocus &&
        !node.skipTraversal &&
        context is Element &&
        _isWithin(context, target);
  });
  final candidate = candidates.lastOrNull;
  expect(candidate, isNotNull, reason: 'No focusable descendant for $key.');
  candidate!.requestFocus();
  await pumpTvFrames(tester, frames: 2);
}

void expectFocusedTargetInsideSafeFrame(
  WidgetTester tester,
  String key,
) {
  final safeFrameFinder = find.byKey(
    const ValueKey('app-presentation-tv-safe-frame'),
  );
  final safeFrame = tester.widget<Padding>(safeFrameFinder);
  final outer = tester.getRect(safeFrameFinder);
  final padding = safeFrame.padding.resolve(TextDirection.ltr);
  final safeRect = Rect.fromLTRB(
    outer.left + padding.left,
    outer.top + padding.top,
    outer.right - padding.right,
    outer.bottom - padding.bottom,
  );
  expect(
    safeRect.contains(tester.getCenter(find.byKey(ValueKey(key)))),
    isTrue,
    reason: '$key must remain within the ten-foot safe frame.',
  );
}

bool _isWithin(Element element, Element ancestor) {
  if (identical(element, ancestor)) {
    return true;
  }
  var found = false;
  element.visitAncestorElements((candidate) {
    if (identical(candidate, ancestor)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
