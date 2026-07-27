import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/platform_capabilities_resolver.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PlatformCapabilities capabilities;
  late AppLocale originalLocale;

  setUpAll(() async {
    originalLocale = LocaleSettings.currentLocale;
    if (_allowInjectedHostCapability) {
      capabilities = const PlatformCapabilities(
        platform: 'android',
        isWeb: false,
        tvPlatform: AppTvPlatform.androidTv,
      );
    } else {
      capabilities = await const PlatformCapabilitiesResolver().resolve();
    }
    expect(
      capabilities.isTelevision,
      isTrue,
      reason: 'The device must be natively detected as Android TV or tvOS.',
    );
  });

  tearDownAll(() async {
    await LocaleSettings.setLocale(originalLocale);
  });

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('native TV shell traverses nested focus regions without skipping', (
    tester,
  ) async {
    await _pumpDeviceApp(tester, capabilities: capabilities);

    expect(find.byKey(const ValueKey('television-shell')), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.home',
    );

    await _press(tester, LogicalKeyboardKey.arrowRight);
    _expectFocused(tester, 'home-open-profile');
    _expectInsideSafeFrame(tester, 'home-open-profile');

    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.home',
    );

    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );

    await _press(tester, LogicalKeyboardKey.arrowRight);
    _expectFocused(tester, 'billing-monthly');
    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.pricing',
    );

    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('settings-wide-navigation')), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.settings',
    );

    await _press(tester, LogicalKeyboardKey.arrowRight);
    _expectFocused(tester, 'settings-wide-appearance');
    final settingsNavigationFocus = FocusManager.instance.primaryFocus;
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(
      FocusManager.instance.primaryFocus,
      isNot(same(settingsNavigationFocus)),
      reason: 'Right must hand focus from settings navigation into content.',
    );
    await _press(tester, LogicalKeyboardKey.arrowLeft);
    _expectFocused(tester, 'settings-wide-appearance');
    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.settings',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV Back prioritizes editor, dialog, route, and invoker focus', (
    tester,
  ) async {
    await _pumpDeviceApp(tester, capabilities: capabilities);

    await _requestFocusWithin(tester, 'home-open-login');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('auth-login-page')), findsOneWidget);
    _expectFocused(tester, 'auth-login-email-activation');

    await _press(tester, LogicalKeyboardKey.enter);
    _expectFocused(tester, 'auth-login-email');
    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      'viewer@example.com',
    );
    await _sendBack(tester, LogicalKeyboardKey.goBack, capabilities);
    expect(find.byKey(const ValueKey('auth-login-page')), findsOneWidget);
    _expectFocused(tester, 'auth-login-email-activation');

    await _sendBack(tester, LogicalKeyboardKey.goBack, capabilities);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    _expectFocused(tester, 'home-open-login');

    await _requestFocusWithin(tester, 'home-open-profile');
    await _press(tester, LogicalKeyboardKey.enter);
    _expectFocused(tester, 'profile-display-name-activation');

    await _press(tester, LogicalKeyboardKey.enter);
    _expectFocused(tester, 'profile-display-name');
    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name')),
      'TV viewer',
    );
    await _sendBack(tester, LogicalKeyboardKey.gameButtonB, capabilities);
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsNothing);
    _expectFocused(tester, 'profile-display-name-activation');

    await _sendBack(tester, LogicalKeyboardKey.goBack, capabilities);
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsOneWidget);
    _expectFocused(tester, 'profile-keep-editing');
    await _sendBack(tester, LogicalKeyboardKey.gameButtonB, capabilities);
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsNothing);
    _expectFocused(tester, 'profile-display-name-activation');
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV OTP and modal controls expose safe actionable focus', (
    tester,
  ) async {
    await _pumpDeviceApp(
      tester,
      capabilities: capabilities,
      initialLocation: AppRoutes.otpLocation(OtpPurpose.registration),
    );

    _expectFocused(tester, 'auth-otp-code-activation');
    expect(find.byKey(const ValueKey('auth-otp-code')), findsNothing);
    await _press(tester, LogicalKeyboardKey.enter);
    _expectFocused(tester, 'auth-otp-code');
    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-code')),
      '12',
    );
    await _sendBack(tester, LogicalKeyboardKey.goBack, capabilities);
    _expectFocused(tester, 'auth-otp-code-activation');
    expect(find.text('••••••••'), findsOneWidget);
    expect(find.text('12'), findsNothing);

    await _pumpDeviceApp(
      tester,
      capabilities: capabilities,
      initialLocation: AppRoutes.pricingPath,
    );
    await _requestFocusWithin(tester, 'select-plan-basic');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    _expectFocused(tester, 'information-dialog-close');

    await _sendBack(tester, LogicalKeyboardKey.gameButtonB, capabilities);
    expect(find.byKey(const ValueKey('information-dialog')), findsNothing);
    _expectFocused(tester, 'select-plan-basic');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDeviceApp(
  WidgetTester tester, {
  required PlatformCapabilities capabilities,
  String? initialLocation,
}) async {
  final config = AppConfig.fromEnvironment();
  expect(config.environment, AppEnvironment.development);
  await tester.pumpWidget(
    App(
      config: config,
      dependencies: AppDependencies.inMemory(
        platformCapabilities: capabilities,
      ),
      initialLocation: initialLocation,
    ),
  );
  await pumpAppFrames(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyEvent(key);
  await pumpAppFrames(tester);
}

Future<void> _sendBack(
  WidgetTester tester,
  LogicalKeyboardKey logicalKey,
  PlatformCapabilities capabilities,
) async {
  if (logicalKey == LogicalKeyboardKey.goBack &&
      capabilities.tvPlatform == AppTvPlatform.androidTv) {
    await tester.binding.handlePopRoute();
    await pumpAppFrames(tester);
    return;
  }
  await tester.sendKeyDownEvent(
    logicalKey,
    physicalKey: PhysicalKeyboardKey.escape,
  );
  await tester.pump();
  await tester.sendKeyUpEvent(
    logicalKey,
    physicalKey: PhysicalKeyboardKey.escape,
  );
  await pumpAppFrames(tester);
}

void _expectFocused(WidgetTester tester, String key) {
  expect(
    _focusIsWithin(tester, key),
    isTrue,
    reason: FocusManager.instance.primaryFocus?.toStringDeep(),
  );
}

bool _focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }
  return _isWithin(focusContext, tester.element(find.byKey(ValueKey(key))));
}

Future<void> _requestFocusWithin(
  WidgetTester tester,
  String key,
) async {
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
  await pumpAppFrames(tester);
}

void _expectInsideSafeFrame(WidgetTester tester, String key) {
  final safeFrameFinder = find.byKey(
    const ValueKey('app-presentation-tv-safe-frame'),
  );
  final safeFrame = tester.widget<Padding>(safeFrameFinder);
  final outer = tester.getRect(safeFrameFinder);
  final direction = Directionality.of(tester.element(safeFrameFinder));
  final padding = safeFrame.padding.resolve(direction);
  final safeRect = Rect.fromLTRB(
    outer.left + padding.left,
    outer.top + padding.top,
    outer.right - padding.right,
    outer.bottom - padding.bottom,
  );
  expect(
    safeRect.contains(tester.getCenter(find.byKey(ValueKey(key)))),
    isTrue,
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

const _allowInjectedHostCapability = bool.fromEnvironment(
  'TV_DEVICE_TEST_ALLOW_INJECTED',
);
