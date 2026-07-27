import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/keyboard/app_keyboard_host.dart';
import 'package:starter/i18n/translations.g.dart';
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
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1024, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleSettings.setLocale(AppLocale.en);
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      dependencies: AppDependencies.inMemory(),
    ),
  );
  await tester.pumpAndSettle();
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
);
