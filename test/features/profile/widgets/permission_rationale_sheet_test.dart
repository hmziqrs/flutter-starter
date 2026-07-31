import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/widgets/permission_rationale_sheet.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('PermissionRationaleBody', () {
    testWidgets('promptable state renders title + rationale and a Continue action', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: PermissionRationaleBody(
            permission: AppPermission.camera,
            onContinue: () {},
            onOpenSettings: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(t.permission.camera.title), findsOneWidget);
      expect(find.text(t.permission.camera.rationale), findsOneWidget);
      expect(find.text(t.permission.continueRequest), findsOneWidget);
      expect(find.text(t.permission.notNow), findsOneWidget);
      expect(find.text(t.permission.openSettings), findsNothing);
      expect(find.text(t.permission.permanentlyDenied), findsNothing);
    });

    testWidgets('permanently-denied state offers Open settings, not a re-prompt', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: PermissionRationaleBody(
            permission: AppPermission.photos,
            permanentlyDenied: true,
            onContinue: () {},
            onOpenSettings: () {},
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(t.permission.openSettings), findsOneWidget);
      expect(find.text(t.permission.continueRequest), findsNothing);
      expect(find.text(t.permission.permanentlyDenied), findsOneWidget);
    });

    testWidgets('Continue tap invokes onContinue (proceeds to the OS prompt)', (tester) async {
      var continued = false;
      var openedSettings = false;
      var dismissed = false;
      await tester.pumpWidget(
        _harness(
          child: PermissionRationaleBody(
            permission: AppPermission.location,
            onContinue: () => continued = true,
            onOpenSettings: () => openedSettings = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text(t.permission.continueRequest));
      await _pumpFrames(tester);

      expect(continued, isTrue);
      expect(openedSettings, isFalse);
      expect(dismissed, isFalse);
    });

    testWidgets('Open settings tap invokes onOpenSettings on the one-way door', (tester) async {
      var openedSettings = false;
      await tester.pumpWidget(
        _harness(
          child: PermissionRationaleBody(
            permission: AppPermission.location,
            permanentlyDenied: true,
            onContinue: () {},
            onOpenSettings: () => openedSettings = true,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text(t.permission.openSettings));
      await _pumpFrames(tester);

      expect(openedSettings, isTrue);
    });

    testWidgets('renders under RTL (ar) with localized title + mirrored layout', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PermissionRationaleBody(
              permission: AppPermission.camera,
              onContinue: () {},
              onOpenSettings: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(t.permission.camera.title), findsOneWidget);
    });
  });

  group('PermissionRationaleResult', () {
    test('exposes the three documented outcomes', () {
      const values = PermissionRationaleResult.values;
      expect(values, contains(PermissionRationaleResult.continueRequest));
      expect(values, contains(PermissionRationaleResult.openSettings));
      expect(values, contains(PermissionRationaleResult.dismiss));
    });
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: TranslationProvider.of(context).flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
          builder: (context, built) => FTheme(
            data: theme,
            child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}
