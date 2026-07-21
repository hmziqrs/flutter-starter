import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  testWidgets('compact overview exposes every settings section and account flow', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(_app(initialLocation: '/settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-language')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-subscription')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-privacy-about')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-open-account')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-open-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Update profile'), findsOneWidget);
  });

  testWidgets('subscription and privacy actions provide honest destinations', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(_app(initialLocation: '/settings?section=subscription'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-view-pricing')));
    await tester.pumpAndSettle();
    expect(find.text('Plans for the way you work'), findsOneWidget);

    await tester.pumpWidget(_app(initialLocation: '/settings?section=privacy-about'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-open-terms')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('information-dialog')),
        matching: find.text('Terms preview'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('product-specific legal text'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('information-dialog-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('information-dialog-close')), findsNothing);
  });

  testWidgets('expanded settings and accent labels remain localized', (tester) async {
    _setViewport(tester, const Size(1024, 844));
    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(_app(initialLocation: '/settings/appearance'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);
    expect(find.text('أزرق'), findsOneWidget);
    expect(find.text('blue'), findsNothing);
    expect(Directionality.of(tester.element(find.text('أزرق'))), TextDirection.rtl);
  });
}

Widget _app({required String initialLocation}) {
  return App(
    config: _developmentConfig,
    dependencies: AppDependencies.inMemory(),
    initialLocation: initialLocation,
  );
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
