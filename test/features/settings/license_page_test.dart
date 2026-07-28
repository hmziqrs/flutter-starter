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
      // Locale pinned so the rendered strings are deterministic and the title
      // lookup below matches exactly.
      await LocaleSettings.setLocale(AppLocale.en);
    });

    testWidgets('renders the license title and version from a package_info fixture', (
      tester,
    ) async {
      // Seed the binding with a deterministic package_info fixture so the page's
      // AppBuildInfo.load() resolves without a real platform channel.
      PackageInfo.setMockInitialValues(
        appName: 'Starter',
        packageName: 'com.example.starter',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );

      await tester.pumpWidget(_harness());
      // Let the AppBuildInfo future resolve; never pumpAndSettle to avoid
      // depending on animation completion (the license list itself is static).
      await tester.pump(const Duration(milliseconds: 10));

      // The localized license title (locale pinned to en in setUp) is rendered
      // as the app bar heading. findsWidgets because the Material LicensePage
      // also exposes the title in its own header chrome.
      expect(find.text('Licenses'), findsWidgets);
      // The version + buildNumber fixture surfaces in the LicensePage header.
      expect(find.text('1.2.3+42'), findsOneWidget);
    });

    testWidgets('degrades to a dash when PackageInfo is unavailable', (tester) async {
      // A blank fixture (no version) still builds the page; the FutureBuilder
      // falls back to the honest dash rather than throwing into the list.
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
      // Empty version+buildNumber -> displayValue is '+', which is not a useful
      // label, so the page degrades to the honest dash placeholder (no
      // fabricated version string).
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
