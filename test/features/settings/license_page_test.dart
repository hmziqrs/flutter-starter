import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  group('AboutLicensePage', () {
    setUp(() async {
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets('renders the license title and version from a package_info fixture', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'Starter',
        packageName: 'com.example.starter',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );

      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Licenses'), findsWidgets);
      expect(find.text('1.2.3+42'), findsOneWidget);
    });

    testWidgets('degrades to a dash when PackageInfo is unavailable', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: '',
        packageName: '',
        version: '',
        buildNumber: '',
        buildSignature: '',
      );

      await tester.pumpWidget(_harness());
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Licenses'), findsWidgets);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('honors an explicit applicationName override', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Ignored',
        packageName: 'com.example.starter',
        version: '2.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      await tester.pumpWidget(_harness(applicationName: 'My Custom App'));
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('My Custom App'), findsOneWidget);
    });
  });
}

Widget _harness({String? applicationName}) {
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  return TranslationProvider(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: theme.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: theme,
        child: child ?? const SizedBox.shrink(),
      ),
      home: AboutLicensePage(applicationName: applicationName),
    ),
  );
}
