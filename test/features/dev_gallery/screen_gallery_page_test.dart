import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/screen_gallery_page.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  testWidgets('renders every control without overflow on a compact host', (tester) async {
    await _pumpGallery(tester);

    expect(find.byKey(const ValueKey('gallery-compact-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-preview-viewport')), findsOneWidget);
    for (final preset in GalleryViewportPresets.values) {
      expect(find.byKey(ValueKey('gallery-viewport-${preset.id}')), findsOneWidget);
    }
    for (final accent in AppAccent.values) {
      expect(find.byKey(ValueKey('gallery-accent-${accent.name}')), findsOneWidget);
    }
    for (final locale in AppLocale.values) {
      expect(find.byKey(ValueKey('gallery-locale-${locale.name}')), findsOneWidget);
    }
    for (final policy in AppInteractionPolicy.values) {
      expect(find.byKey(ValueKey('gallery-interaction-${policy.name}')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('filters localized screens and cases, then selects a case', (tester) async {
    await _pumpGallery(tester);
    expect(find.byKey(const ValueKey('case-probe-home-default')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('gallery-search')), 'Login');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-screen-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-screen-home')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gallery-screen-login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gallery-case-login.default')), findsOneWidget);
    expect(find.byKey(const ValueKey('case-probe-login-default')), findsOneWidget);
  });

  testWidgets('keeps case selection while environment controls change', (tester) async {
    await _pumpGallery(tester);
    await _tapControl(tester, const ValueKey('gallery-case-home.empty'));
    expect(find.byKey(const ValueKey('case-probe-home-empty')), findsOneWidget);

    await _tapControl(tester, const ValueKey('gallery-theme-dark'));
    expect(find.byKey(const ValueKey('case-probe-home-empty')), findsOneWidget);
    final probeContext = tester.element(find.byKey(const ValueKey('case-probe-home-empty')));
    expect(Theme.of(probeContext).brightness, Brightness.dark);

    await _tapControl(tester, const ValueKey('gallery-viewport-at-medium'));
    expect(find.byKey(const ValueKey('case-probe-home-empty')), findsOneWidget);
    expect(MediaQuery.sizeOf(probeContext), const Size(640, 900));
  });

  testWidgets('locale control applies RTL and restores the prior locale on disposal', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await _pumpGallery(tester, setLocale: false);

    await _tapControl(tester, const ValueKey('gallery-locale-ar'));
    await tester.pumpAndSettle();
    final probe = tester.element(find.byKey(const ValueKey('case-probe-home-default')));
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    expect(Directionality.of(probe), TextDirection.rtl);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(LocaleSettings.currentLocale, AppLocale.en);
  });

  testWidgets('reset restores defaults without changing the selected case', (tester) async {
    await _pumpGallery(tester);
    await _tapControl(tester, const ValueKey('gallery-case-home.empty'));
    await _tapControl(tester, const ValueKey('gallery-theme-dark'));
    await _tapControl(tester, const ValueKey('gallery-safe-area-enabled'));
    await _tapControl(tester, const ValueKey('gallery-reset-controls'));

    expect(find.byKey(const ValueKey('case-probe-home-empty')), findsOneWidget);
    final probe = tester.element(find.byKey(const ValueKey('case-probe-home-empty')));
    expect(Theme.of(probe).brightness, Brightness.light);
    expect(MediaQuery.paddingOf(probe), EdgeInsets.zero);
  });
}

final _cases = <GalleryCase>[
  _TestCase(
    id: 'home.default',
    screenId: 'home',
    screenLabel: (translations) => translations.devGallery.screenHome,
    caseLabel: (translations) => translations.devGallery.caseDefault,
  ),
  _TestCase(
    id: 'home.empty',
    screenId: 'home',
    screenLabel: (translations) => translations.devGallery.screenHome,
    caseLabel: (translations) => translations.devGallery.caseEmpty,
  ),
  _TestCase(
    id: 'login.default',
    screenId: 'login',
    screenLabel: (translations) => translations.devGallery.screenLogin,
    caseLabel: (translations) => translations.devGallery.caseDefault,
  ),
];

Future<void> _pumpGallery(WidgetTester tester, {bool setLocale = true}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  if (setLocale) await LocaleSettings.setLocale(AppLocale.en);
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: theme,
          child: child ?? const SizedBox.shrink(),
        ),
        home: ScreenGalleryPage(cases: _cases),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapControl(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final class _TestCase implements GalleryCase {
  const _TestCase({
    required this.id,
    required this.screenId,
    required this._screenLabel,
    required this._caseLabel,
  });

  @override
  final String id;

  @override
  final String screenId;

  final GalleryLabelBuilder _screenLabel;
  final GalleryLabelBuilder _caseLabel;

  @override
  String screenLabel(Translations translations) => _screenLabel(translations);

  @override
  String caseLabel(Translations translations) => _caseLabel(translations);

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: ValueKey('case-probe-${id.replaceAll('.', '-')}'));
  }
}
