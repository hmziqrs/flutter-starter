import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/diagnostics/diagnostics_page.dart';
import 'package:starter/app/routing/route_error_page.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/system/system_gallery_cases.dart';
import 'package:starter/i18n/translations.g.dart';

import 'system_gallery_test_harness.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('system and overlay case IDs are stable and unique', () {
    final cases = buildSystemGalleryCases(config: _developmentConfig);
    final ids = cases.map((galleryCase) => galleryCase.id).toList();

    expect(
      ids,
      const [
        'system.startupFailure',
        'system.unknownRoute',
        'system.malformedOtp',
        'system.diagnostics',
        'overlays.dialog',
        'overlays.sheet',
        'overlays.toast',
        'overlays.popover',
        'overlays.tooltip',
        'overlays.keyboardInset',
      ],
    );
    expect(ids.toSet(), hasLength(ids.length));
    expect(cases.take(4).map((galleryCase) => galleryCase.screenId).toSet(), {'system'});
    expect(cases.skip(4).map((galleryCase) => galleryCase.screenId).toSet(), {'overlays'});
  });

  test('case labels come from the localized gallery catalog', () {
    final translations = AppLocale.en.buildSync();
    final cases = buildSystemGalleryCases(config: _developmentConfig);

    expect(_caseById(cases, 'system.startupFailure').caseLabel(translations), 'Startup failure');
    expect(
      _caseById(cases, 'overlays.keyboardInset').caseLabel(translations),
      'Keyboard-inset form',
    );
    expect(_caseById(cases, 'system.diagnostics').screenLabel(translations), 'System surfaces');
    expect(_caseById(cases, 'overlays.dialog').screenLabel(translations), 'Overlays');
  });

  testWidgets('system cases render the real production surface types', (tester) async {
    final cases = buildSystemGalleryCases(config: _developmentConfig);

    await tester.pumpWidget(
      systemGalleryTestApp(galleryCase: _caseById(cases, 'system.startupFailure')),
    );
    expect(find.byType(StartupErrorView), findsOneWidget);
    expect(find.textContaining('STARTUP-CONFIG'), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-retry')), findsOneWidget);

    await tester.pumpWidget(
      systemGalleryTestApp(galleryCase: _caseById(cases, 'system.unknownRoute')),
    );
    expect(find.byType(RouteErrorPage), findsOneWidget);
    expect(find.textContaining('/gallery/unknown'), findsOneWidget);

    await tester.pumpWidget(
      systemGalleryTestApp(galleryCase: _caseById(cases, 'system.malformedOtp')),
    );
    expect(find.byType(RouteErrorPage), findsOneWidget);
    expect(
      find.text('The verification address needs a valid registration or password-reset purpose.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      systemGalleryTestApp(galleryCase: _caseById(cases, 'system.diagnostics')),
    );
    expect(find.byType(DiagnosticsPage), findsOneWidget);
  });

  testWidgets('route recovery action gives persistent honest feedback', (tester) async {
    final galleryCase = _caseById(
      buildSystemGalleryCases(config: _developmentConfig),
      'system.unknownRoute',
    );
    await tester.pumpWidget(systemGalleryTestApp(galleryCase: galleryCase));

    await tester.tap(find.byKey(const ValueKey('route-error-home')));
    await tester.pump();
    expect(find.byType(FToast), findsOneWidget);
    expect(find.text('This action is not connected yet.'), findsOneWidget);

    await tester.pump(const Duration(minutes: 1));
    expect(find.byType(FToast), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('system-feedback-close')));
    await tester.pumpAndSettle();
    expect(find.byType(FToast), findsNothing);
  });

  testWidgets('startup recovery action is enabled and gives honest feedback', (tester) async {
    final galleryCase = _caseById(
      buildSystemGalleryCases(config: _developmentConfig),
      'system.startupFailure',
    );
    await tester.pumpWidget(systemGalleryTestApp(galleryCase: galleryCase));

    await tester.tap(find.byKey(const ValueKey('startup-retry')));
    await tester.pump(const Duration(milliseconds: 101));

    expect(find.text('This action is not connected yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('system-feedback-close')), findsOneWidget);
  });
}

GalleryCase _caseById(List<GalleryCase> cases, String id) {
  return cases.singleWhere((galleryCase) => galleryCase.id == id);
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
);
