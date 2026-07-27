import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/shell/app_shell.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/pricing/widgets/plan_card.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  final cases = buildGalleryRegistry(config: _developmentConfig);

  testWidgets('shell selection changes exactly below and at sm and lg', (tester) async {
    _configureHostView(tester);
    final home = _caseById(cases, 'home.default');

    for (final expectation in <({String viewportId, String shellKey, String layoutKey})>[
      (
        viewportId: 'below-medium',
        shellKey: 'compact-navigation',
        layoutKey: 'home-layout-compact',
      ),
      (
        viewportId: 'at-medium',
        shellKey: 'medium-shell',
        layoutKey: 'home-layout-medium',
      ),
      (
        viewportId: 'below-expanded',
        shellKey: 'medium-shell',
        layoutKey: 'home-layout-medium',
      ),
      (
        viewportId: 'at-expanded',
        shellKey: 'expanded-shell',
        layoutKey: 'home-layout-expanded',
      ),
    ]) {
      final environment = GalleryEnvironment.defaults().copyWith(
        viewport: GalleryViewportPresets.byId(expectation.viewportId),
      );
      await _pumpCase(
        tester,
        galleryCase: home,
        environment: environment,
        insideShell: true,
      );

      expect(
        find.byKey(ValueKey(expectation.shellKey)),
        findsOneWidget,
        reason: expectation.viewportId,
      );
      expect(
        find.byKey(ValueKey(expectation.layoutKey)),
        findsOneWidget,
        reason: expectation.viewportId,
      );
      expect(tester.takeException(), isNull, reason: expectation.viewportId);
    }
  });

  testWidgets('pricing reflows at boundaries and retains billing state', (tester) async {
    _configureHostView(tester);
    final pricing = _caseById(cases, 'pricing.monthly');
    var environment = GalleryEnvironment.defaults().copyWith(
      viewport: GalleryViewportPresets.byId('below-medium'),
    );

    await _pumpCase(tester, galleryCase: pricing, environment: environment);
    expect(find.byKey(const ValueKey('pricing-layout-compact')), findsOneWidget);
    _expectPlanRows(tester, expectedRows: 3);

    await tester.tap(find.byKey(const ValueKey('billing-annual')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('billing-annual'))).selected,
      isTrue,
    );

    environment = environment.copyWith(
      viewport: GalleryViewportPresets.byId('at-medium'),
    );
    await _pumpCase(tester, galleryCase: pricing, environment: environment);
    expect(find.byKey(const ValueKey('pricing-layout-medium')), findsOneWidget);
    _expectPlanRows(tester, expectedRows: 2);
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('billing-annual'))).selected,
      isTrue,
    );

    environment = environment.copyWith(
      viewport: GalleryViewportPresets.byId('below-expanded'),
    );
    await _pumpCase(tester, galleryCase: pricing, environment: environment);
    expect(find.byKey(const ValueKey('pricing-layout-medium')), findsOneWidget);
    _expectPlanRows(tester, expectedRows: 2);

    environment = environment.copyWith(
      viewport: GalleryViewportPresets.byId('at-expanded'),
    );
    await _pumpCase(tester, galleryCase: pricing, environment: environment);
    expect(find.byKey(const ValueKey('pricing-layout-expanded')), findsOneWidget);
    _expectPlanRows(tester, expectedRows: 1);
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('billing-annual'))).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth values and focus survive compact to expanded live resize', (tester) async {
    _configureHostView(tester);
    final login = _caseById(cases, 'auth.login.idle');
    var environment = GalleryEnvironment.defaults();

    await _pumpCase(tester, galleryCase: login, environment: environment);
    final email = _editableInside(const ValueKey('auth-login-email'));
    final password = _editableInside(const ValueKey('auth-login-password'));
    await tester.enterText(email, 'sam@example.com');
    await tester.enterText(password, 'not-trimmed ');
    await tester.showKeyboard(password);
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);

    environment = environment.copyWith(
      viewport: GalleryViewportPresets.byId('at-medium'),
    );
    await _pumpCase(tester, galleryCase: login, environment: environment);
    expect(_textIn(tester, email), 'sam@example.com');
    expect(_textIn(tester, password), 'not-trimmed ');
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);

    environment = environment.copyWith(
      viewport: GalleryViewportPresets.byId('at-expanded'),
    );
    await _pumpCase(tester, galleryCase: login, environment: environment);
    expect(find.byKey(const ValueKey('auth-login-layout-expanded')), findsOneWidget);
    expect(_textIn(tester, email), 'sam@example.com');
    expect(_textIn(tester, password), 'not-trimmed ');
    expect(tester.widget<EditableText>(password).focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings changes from compact list to wide detail at sm', (tester) async {
    _configureHostView(tester);
    final settings = _caseById(cases, 'settings.overview');

    await _pumpCase(
      tester,
      galleryCase: settings,
      environment: GalleryEnvironment.defaults().copyWith(
        viewport: GalleryViewportPresets.byId('below-medium'),
      ),
    );
    expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
    expect(find.byKey(const ValueKey('font-scale-slider')), findsNothing);

    await _pumpCase(
      tester,
      galleryCase: settings,
      environment: GalleryEnvironment.defaults().copyWith(
        viewport: GalleryViewportPresets.byId('at-medium'),
      ),
    );
    expect(find.byKey(const ValueKey('settings-open-appearance')), findsNothing);
    expect(find.byKey(const ValueKey('font-scale-slider')), findsOneWidget);
    expect(find.byType(FSidebarItem), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape RTL safe-area and fold fixture keeps auth usable', (tester) async {
    _configureHostView(tester);
    final login = _caseById(cases, 'auth.login.invalid');
    final environment = GalleryEnvironment.defaults().copyWith(
      viewport: GalleryViewportPresets.byId('short-phone'),
      locale: AppLocale.ar,
      safeAreaEnabled: true,
      displayFeature: GalleryDisplayFeature.verticalFold,
    );

    await _pumpCase(tester, galleryCase: login, environment: environment);
    final pageContext = tester.element(find.byKey(const ValueKey('auth-login-page')));
    final mediaQuery = MediaQuery.of(pageContext);
    final submit = find.byKey(const ValueKey('auth-login-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();

    expect(Directionality.of(pageContext), TextDirection.rtl);
    expect(mediaQuery.padding, PreviewFrame.safeAreaPadding);
    expect(mediaQuery.viewPadding, PreviewFrame.safeAreaPadding);
    expect(mediaQuery.displayFeatures, hasLength(1));
    expect(mediaQuery.displayFeatures.single.type, DisplayFeatureType.fold);
    expect(mediaQuery.displayFeatures.single.bounds, const Rect.fromLTWH(414, 0, 16, 390));
    expect(submit, findsOneWidget);
    expect(tester.widget<FButton>(submit).onPress, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard inset leaves compact auth form scrollable and actionable', (tester) async {
    _configureHostView(tester);
    final login = _caseById(cases, 'auth.login.idle');
    final environment = GalleryEnvironment.defaults().copyWith(
      safeAreaEnabled: true,
      keyboardInsetsEnabled: true,
    );

    await _pumpCase(tester, galleryCase: login, environment: environment);
    final page = find.byKey(const ValueKey('auth-login-page'));
    final pageContext = tester.element(page);
    final formScroll = find.descendant(of: page, matching: find.byType(ListView));
    final submit = find.byKey(const ValueKey('auth-login-submit'));

    expect(MediaQuery.viewInsetsOf(pageContext), PreviewFrame.keyboardInsets);
    expect(formScroll, findsOneWidget);
    final scrollable = find.descendant(of: formScroll, matching: find.byType(Scrollable));
    final scrollableState = tester.state<ScrollableState>(scrollable.first);
    expect(scrollableState.position.maxScrollExtent, greaterThan(0));
    scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
    await tester.pump();
    expect(submit, findsOneWidget);
    expect(tester.widget<FButton>(submit).onPress, isNotNull);
    expect(tester.getRect(submit).overlaps(tester.getRect(page)), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all app multipliers compose with normal and nonlinear system scaling', (
    tester,
  ) async {
    _configureHostView(tester);
    final login = _caseById(cases, 'auth.login.invalid');

    for (final appScale in const [0.85, 1.0, 1.6]) {
      for (final systemScale in GallerySystemTextScale.values) {
        final environment = GalleryEnvironment.defaults().copyWith(
          appFontScale: appScale,
          systemTextScale: systemScale,
        );
        await _pumpCase(tester, galleryCase: login, environment: environment);
        final context = tester.element(find.byKey(const ValueKey('auth-login-page')));
        final appFontSize = context.theme.typography.body.md.fontSize!;
        final expectedTheme = ForuiThemeFactory.build(
          brightness: Brightness.light,
          accent: AppAccent.neutral,
          fontScale: appScale,
          interactionPolicy: AppInteractionPolicy.touch,
        );
        final expectedScaledSize = switch (systemScale) {
          GallerySystemTextScale.normal => appFontSize,
          GallerySystemTextScale.maximumNonlinear => const GalleryMaximumTextScaler().scale(
            appFontSize,
          ),
        };

        expect(appFontSize, expectedTheme.typography.body.md.fontSize);
        expect(MediaQuery.textScalerOf(context).scale(appFontSize), expectedScaledSize);
        if (systemScale == GallerySystemTextScale.maximumNonlinear) {
          expect(MediaQuery.textScalerOf(context), isA<GalleryMaximumTextScaler>());
        }
        expect(find.byKey(const ValueKey('auth-login-submit')), findsOneWidget);
        expect(
          tester.widget<FButton>(find.byKey(const ValueKey('auth-login-submit'))).onPress,
          isNotNull,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'app=$appScale, system=${systemScale.name}',
        );
      }
    }
  });

  testWidgets('disabled motion, high contrast and bold text preserve settings actions', (
    tester,
  ) async {
    _configureHostView(tester);
    final settings = _caseById(cases, 'settings.appearance');
    final environment = GalleryEnvironment.defaults().copyWith(
      viewport: GalleryViewportPresets.byId('medium'),
      locale: AppLocale.zhHans,
      appFontScale: 1.6,
      systemTextScale: GallerySystemTextScale.maximumNonlinear,
      animationsEnabled: false,
      highContrast: true,
      boldText: true,
    );

    await _pumpCase(tester, galleryCase: settings, environment: environment);
    final slider = find.byKey(const ValueKey('font-scale-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final context = tester.element(slider);
    final mediaQuery = MediaQuery.of(context);

    expect(mediaQuery.disableAnimations, isTrue);
    expect(mediaQuery.highContrast, isTrue);
    expect(mediaQuery.boldText, isTrue);
    expect(MediaQuery.textScalerOf(context), isA<GalleryMaximumTextScaler>());
    expect(find.byKey(const ValueKey('theme-system')), findsOneWidget);
    expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
    expect(
      tester.widget<FButton>(find.byKey(const ValueKey('theme-system'))).onPress,
      isNotNull,
    );
    expect(find.byIcon(FLucideIcons.sparkles), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _configureHostView(WidgetTester tester) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(1600, 1100);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() => LocaleSettings.setLocale(AppLocale.en));
}

Future<void> _pumpCase(
  WidgetTester tester, {
  required GalleryCase galleryCase,
  required GalleryEnvironment environment,
  bool insideShell = false,
}) async {
  await LocaleSettings.setLocale(environment.locale);
  final hostTheme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_settingsRepository),
        initialSettingsProvider.overrideWithValue(const SettingsState.defaults()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          locale: environment.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: hostTheme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: hostTheme,
            child: child ?? const SizedBox.shrink(),
          ),
          home: PreviewFrame(
            environment: environment,
            child: _GalleryCaseSurface(
              galleryCase: galleryCase,
              insideShell: insideShell,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _GalleryCaseSurface extends StatelessWidget {
  const _GalleryCaseSurface({
    required this.galleryCase,
    required this.insideShell,
  });

  final GalleryCase galleryCase;
  final bool insideShell;

  @override
  Widget build(BuildContext context) {
    final page = galleryCase.build(context);
    return insideShell ? AppShell.preview(child: page) : page;
  }
}

GalleryCase _caseById(List<GalleryCase> cases, String id) {
  return cases.singleWhere((galleryCase) => galleryCase.id == id);
}

Finder _editableInside(ValueKey<String> key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(EditableText));
}

String _textIn(WidgetTester tester, Finder finder) {
  return tester.widget<EditableText>(finder).controller.text;
}

void _expectPlanRows(WidgetTester tester, {required int expectedRows}) {
  final cards = find.byType(PlanCard);
  expect(cards, findsNWidgets(3));
  final rowOffsets = <double>{
    for (final element in cards.evaluate()) tester.getTopLeft(find.byWidget(element.widget)).dy,
  };
  expect(rowOffsets, hasLength(expectedRows));
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
);

final _settingsRepository = SettingsRepository(InMemorySettingsStore());
