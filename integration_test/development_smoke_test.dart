import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

import 'integration_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('development production-composition smoke flow persists settings', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.development);
    expect(config.developmentToolsEnabled, isTrue);

    await resetTestSettings();
    addTearDown(resetTestSettings);
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(await createApplication(config));
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    await _go(tester, AppRoutes.onboardingPath);
    for (var index = 0; index < 3; index += 1) {
      await tapVisible(tester, const ValueKey('onboarding-continue'));
    }
    expect(find.byKey(const ValueKey('paywall-page')), findsOneWidget);
    await tapVisible(tester, const ValueKey('paywall-skip'));
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    await _go(tester, AppRoutes.registerPath);
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-display-name')),
      'Sam Rivera',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-email')),
      'sam@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-password')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-register-confirm-password')),
      'Password1',
    );
    await tapVisible(tester, const ValueKey('auth-register-accept-terms'));
    await tapVisible(tester, const ValueKey('auth-register-submit'));
    expect(find.byKey(const ValueKey('auth-otp-page')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('auth-otp-code')), '123456');
    await tapVisible(tester, const ValueKey('auth-otp-submit'));
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    await _go(tester, AppRoutes.updateProfilePath);
    final bio = find.byKey(const ValueKey('profile-bio'));
    await tester.enterText(bio, 'Retained through every layout class.');
    await tester.showKeyboard(bio);
    expect(_editable(tester, bio).focusNode.hasFocus, isTrue);

    for (final size in const [Size(390, 844), Size(800, 1000), Size(1024, 768)]) {
      tester.view.physicalSize = size * tester.view.devicePixelRatio;
      await tester.pump(const Duration(milliseconds: 500));
      expect(_editable(tester, bio).controller.text, 'Retained through every layout class.');
    }
    tester.view.physicalSize = const Size(390, 844) * tester.view.devicePixelRatio;
    await pumpAppFrames(tester);

    await tapVisible(tester, const ValueKey('profile-save'));
    expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('information-dialog')), findsNothing);

    await _go(tester, AppRoutes.appearanceSettingsPath);
    await tapVisible(tester, const ValueKey('theme-dark'));
    await tapVisible(tester, const ValueKey('accent-blue'));
    final slider = find.byKey(const ValueKey('font-scale-slider'));
    await tester.ensureVisible(slider);
    await pumpAppFrames(tester);
    final sliderTrack = find.descendant(
      of: slider,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onHorizontalDragStart != null,
      ),
    );
    expect(sliderTrack, findsWidgets);
    final sliderBounds = tester.getRect(sliderTrack.first);
    await tester.tapAt(sliderBounds.centerRight - const Offset(1, 0));
    await pumpAppFrames(tester);

    await _go(tester, AppRoutes.languageSettingsPath);
    await tapVisible(tester, const ValueKey('locale-ar'));
    final liveState = _settingsState(tester);
    expect(liveState.themeMode, AppThemeMode.dark);
    expect(liveState.accent, AppAccent.blue);
    expect(liveState.fontScale, SettingsState.maximumFontScale);
    expect(liveState.localeOverride, AppLocale.ar);
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('locale-ar')))),
      TextDirection.rtl,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpAppFrames(tester);
    await tester.pumpWidget(await createApplication(config));
    await pumpAppFrames(tester);

    final restoredState = _settingsState(tester);
    expect(restoredState, liveState);
    expect(
      Theme.of(tester.element(find.byKey(const ValueKey('home-greeting')))).brightness,
      Brightness.dark,
    );
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('home-greeting')))),
      TextDirection.rtl,
    );
  });
}

Future<void> _go(WidgetTester tester, String location) async {
  final rootContext = tester.element(find.byType(Navigator).first);
  GoRouter.of(rootContext).go(location);
  await pumpAppFrames(tester);
}

SettingsState _settingsState(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(context).read(settingsControllerProvider);
}

EditableText _editable(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(
    find.descendant(of: field, matching: find.byType(EditableText)),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}
