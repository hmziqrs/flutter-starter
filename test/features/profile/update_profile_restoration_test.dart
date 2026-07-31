import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('restores the in-progress profile draft after restartAndRestore', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _RestorationTestApp(
        home: UpdateProfilePage(
          initialDraft: const ProfileDraft.defaults(),
          onSave: (_) async {},
          onAvatarPicked: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name')),
      'Jordan Lee',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-username')),
      'jordan.lee',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-bio')),
      'Restoring my draft after a cold start.',
    );
    await tester.pump();

    expect(_fieldText(tester, 'profile-display-name'), 'Jordan Lee');
    expect(_fieldText(tester, 'profile-username'), 'jordan.lee');
    expect(_fieldText(tester, 'profile-bio'), 'Restoring my draft after a cold start.');

    await tester.restartAndRestore();
    await tester.pump();

    expect(_fieldText(tester, 'profile-display-name'), 'Jordan Lee');
    expect(_fieldText(tester, 'profile-username'), 'jordan.lee');
    expect(_fieldText(tester, 'profile-bio'), 'Restoring my draft after a cold start.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('still builds with restoration disabled (no scope)', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _NoRestorationTestApp(
        home: UpdateProfilePage(
          initialDraft: const ProfileDraft.defaults(),
          onSave: (_) async {},
          onAvatarPicked: (_) {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(_fieldText(tester, 'profile-display-name'), 'Alex Morgan');
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

String _fieldText(WidgetTester tester, String valueKey) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(ValueKey(valueKey)),
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
                child: FToaster(child: child ?? const SizedBox.shrink()),
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
                child: FToaster(child: child ?? const SizedBox.shrink()),
              ),
            );
          },
        ),
      ),
    );
  }
}
