import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

/// The password is intentionally NOT restored: secrets never participate in restoration.
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('restores the email draft after restartAndRestore', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _RestorationTestApp(
        home: LoginPage(
          onSubmit: (_) async {},
          onForgotPassword: () {},
          onRegister: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
      find.byKey(const ValueKey('auth-login-email')),
      'person@example.com',
    );
    await tester.pump();

    expect(_emailText(tester), 'person@example.com');

    await tester.restartAndRestore();
    await tester.pump();

    expect(_emailText(tester), 'person@example.com');
    expect(_passwordText(tester), '');
    expect(tester.takeException(), isNull);
  });

  testWidgets('still builds with restoration disabled (no scope)', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _NoRestorationTestApp(
        home: LoginPage(
          onSubmit: (_) async {},
          onForgotPassword: () {},
          onRegister: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(_emailText(tester), '');
    expect(find.byKey(const ValueKey('auth-login-email')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _emailText(WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const ValueKey('auth-login-email')),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
}

String _passwordText(WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(const ValueKey('auth-login-password')),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
}

class _RestorationTestApp extends StatelessWidget {
  const _RestorationTestApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (context) {
            final localeData = TranslationProvider.of(context);
            final theme = generated.lightTheme;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              restorationScopeId: 'app',
              home: home,
              locale: localeData.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: FLocalizations.localizationsDelegates,
              theme: theme.toApproximateMaterialTheme(),
              builder: (context, child) => FTheme(
                data: theme,
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoRestorationTestApp extends StatelessWidget {
  const _NoRestorationTestApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: TranslationProvider(
        child: Builder(
          builder: (context) {
            final localeData = TranslationProvider.of(context);
            final theme = generated.lightTheme;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: home,
              locale: localeData.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: FLocalizations.localizationsDelegates,
              theme: theme.toApproximateMaterialTheme(),
              builder: (context, child) => FTheme(
                data: theme,
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
