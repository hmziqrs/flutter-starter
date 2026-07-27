import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/keyboard/app_keyboard_host.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/motion/app_motion.dart';

void main() {
  testWidgets('ordinary keys stay hidden while modifier chords show every held key', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byType(AppKeyboardHost), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(find.byKey(const ValueKey('app-keyboard-chord-overlay')), findsNothing);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1);
    await tester.pump();

    expect(find.byKey(const ValueKey('app-keyboard-chord-overlay')), findsOneWidget);
    expect(find.text('Meta'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump(AppMotion.keyboardChordHold + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-keyboard-chord-overlay')), findsNothing);
  });

  testWidgets('command backspace pops a pushed login screen without an on-screen back button', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('home-open-login')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsWidgets);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Alex'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-keyboard-chord-overlay')), findsOneWidget);
    expect(find.text('⌫'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
  });

  for (final backKey in [
    (
      logical: LogicalKeyboardKey.goBack,
      physical: PhysicalKeyboardKey.escape,
    ),
    (
      logical: LogicalKeyboardKey.gameButtonB,
      physical: PhysicalKeyboardKey.gameButtonB,
    ),
  ]) {
    testWidgets('${backKey.logical} dispatches through the platform Back route', (tester) async {
      await _pumpApp(
        tester,
        capabilities: const PlatformCapabilities(
          platform: 'android',
          isWeb: false,
          tvPlatform: AppTvPlatform.androidTv,
        ),
      );
      await _tapVisible(tester, 'home-open-login');
      expect(find.text('Welcome back'), findsWidgets);

      if (backKey.logical == LogicalKeyboardKey.goBack) {
        await tester.sendKeyDownEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
        await tester.sendKeyUpEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
      } else {
        await tester.sendKeyDownEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Alex'), findsOneWidget);
      if (backKey.logical != LogicalKeyboardKey.goBack) {
        await tester.sendKeyUpEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
      }
    });
  }

  for (final backKey in [
    (
      logical: LogicalKeyboardKey.goBack,
      physical: PhysicalKeyboardKey.escape,
    ),
    (
      logical: LogicalKeyboardKey.gameButtonB,
      physical: PhysicalKeyboardKey.gameButtonB,
    ),
  ]) {
    testWidgets('${backKey.logical} cancels a root TV editor before route Back', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.loginPath,
        capabilities: const PlatformCapabilities(
          platform: 'android',
          isWeb: false,
          tvPlatform: AppTvPlatform.androidTv,
        ),
      );

      expect(
        find.byKey(const ValueKey('auth-login-email-activation')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const ValueKey('auth-login-email')), findsOneWidget);

      if (backKey.logical == LogicalKeyboardKey.goBack) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.sendKeyDownEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
        await tester.pump();
        await tester.sendKeyUpEvent(
          backKey.logical,
          physicalKey: backKey.physical,
        );
      }
      await tester.pump();

      expect(find.byKey(const ValueKey('auth-login-page')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('auth-login-email-activation')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('auth-login-email')), findsNothing);
    });
  }

  testWidgets('password reset returns to the original login and preserves its Home back edge', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _tapVisible(tester, 'home-open-login');
    await _tapVisible(tester, 'auth-login-forgot-password');

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-password-email')),
      'person@example.com',
    );
    await _tapVisible(tester, 'auth-forgot-password-submit');
    await tester.enterText(
      find.byKey(const ValueKey('auth-otp-code')),
      '654321',
    );
    await _tapVisible(tester, 'auth-otp-submit');
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-new')),
      'Password1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-reset-password-confirm')),
      'Password1',
    );
    await _tapVisible(tester, 'auth-reset-password-submit');

    final login = find.byKey(const ValueKey('auth-login-page'));
    expect(login, findsOneWidget);
    expect(find.byKey(const ValueKey('auth-login-success')), findsOneWidget);
    expect(GoRouter.of(tester.element(login)).canPop(), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  PlatformCapabilities capabilities = const PlatformCapabilities.nonTelevision(),
  String? initialLocation,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1024, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleSettings.setLocale(AppLocale.en);
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      initialLocation: initialLocation,
      dependencies: AppDependencies.inMemory(
        platformCapabilities: capabilities,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, String valueKey) async {
  final target = find.byKey(ValueKey(valueKey));
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
);
