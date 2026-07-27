import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('injected Android TV is navigable with only remote keys', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1920, 1080);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      App(
        config: config,
        dependencies: AppDependencies.inMemory(
          platformCapabilities: const PlatformCapabilities(
            platform: 'android',
            isWeb: false,
            tvPlatform: AppTvPlatform.androidTv,
          ),
        ),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('television-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-presentation-tv-safe-frame')),
      findsOneWidget,
    );
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.home',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpAppFrames(tester);
    expect(
      _focusIsWithin(tester, 'home-open-profile'),
      isTrue,
      reason: FocusManager.instance.primaryFocus?.toStringDeep(),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);

    await _sendRemoteKey(
      tester,
      logicalKey: LogicalKeyboardKey.goBack,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpAppFrames(tester);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.home',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);
  });
}

Future<void> _sendRemoteKey(
  WidgetTester tester, {
  required LogicalKeyboardKey logicalKey,
  required PhysicalKeyboardKey physicalKey,
}) async {
  await tester.sendKeyDownEvent(
    logicalKey,
    platform: 'android',
    physicalKey: physicalKey,
  );
  await tester.pump();
  await tester.sendKeyUpEvent(
    logicalKey,
    platform: 'android',
    physicalKey: physicalKey,
  );
}

bool _focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }

  final focusedElement = find.byElementPredicate(
    (element) => identical(element, focusContext),
  );
  return find
      .ancestor(
        of: focusedElement,
        matching: find.byKey(ValueKey(key)),
      )
      .evaluate()
      .isNotEmpty;
}
