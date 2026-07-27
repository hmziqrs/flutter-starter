import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';

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
    final appearanceBounds = tester.getRect(
      find.byKey(const ValueKey('settings-open-appearance')),
    );
    final languageBounds = tester.getRect(
      find.byKey(const ValueKey('settings-open-language')),
    );
    expect(languageBounds.top, greaterThan(appearanceBounds.bottom));

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
    // settings.onOpenPricing is now a branch switch (_goTab), not a push, so
    // there is no in-app Back edge from Pricing to the subscription section.
    expect(
      GoRouter.of(tester.element(find.text('Plans for the way you work'))).canPop(),
      isFalse,
    );

    // Pricing opens as a sibling branch, so system Back no longer returns to
    // the subscription section. Retapping the Settings bottom-nav must restore
    // the saved settings stack via reset-on-retap (goBranch without
    // initialLocation), surfacing the subscription section's pricing affordance
    // again.
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('compact-navigation')),
        matching: find.byIcon(FLucideIcons.settings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-view-pricing')), findsOneWidget);

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

  testWidgets('wide settings navigation keeps equal gaps at medium and expanded widths', (
    tester,
  ) async {
    _setViewport(tester, const Size(640, 844));
    await LocaleSettings.setLocale(AppLocale.en);

    for (final width in [640.0, 1024.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(_app(initialLocation: '/settings/appearance'));
      await tester.pumpAndSettle();

      final itemRects = [
        tester.getRect(find.byKey(const ValueKey('settings-wide-appearance'))),
        tester.getRect(find.byKey(const ValueKey('settings-wide-language'))),
        tester.getRect(find.byKey(const ValueKey('settings-wide-account'))),
        tester.getRect(find.byKey(const ValueKey('settings-wide-subscription'))),
        tester.getRect(find.byKey(const ValueKey('settings-wide-privacy-about'))),
      ];
      final gaps = [
        for (var index = 1; index < itemRects.length; index++)
          itemRects[index].top - itemRects[index - 1].bottom,
      ];

      expect(gaps.first, greaterThan(0));
      for (final gap in gaps.skip(1)) {
        expect(gap, closeTo(gaps.first, 0.01));
      }

      expect(
        tester
            .widget<FSidebarItem>(
              find.byKey(const ValueKey('settings-wide-appearance')),
            )
            .selected,
        isTrue,
      );
    }
  });

  testWidgets('TV directional focus bridges settings navigation and content', (
    tester,
  ) async {
    _setViewport(tester, const Size(1920, 1080));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      _app(
        initialLocation: '/settings/appearance',
        capabilities: const PlatformCapabilities(
          platform: 'android',
          isWeb: false,
          tvPlatform: AppTvPlatform.androidTv,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(
      _focusIsWithin(tester, 'settings-wide-appearance'),
      isTrue,
      reason: FocusManager.instance.primaryFocus?.toStringDeep(),
    );

    final navigationFocus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, isNot(same(navigationFocus)));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      _focusIsWithin(tester, 'settings-wide-appearance'),
      isTrue,
      reason: FocusManager.instance.primaryFocus?.toStringDeep(),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'television.navigation.settings',
    );
  });
}

Widget _app({
  required String initialLocation,
  PlatformCapabilities? capabilities,
}) {
  return App(
    config: _developmentConfig,
    dependencies: AppDependencies.inMemory(
      platformCapabilities: capabilities ?? const PlatformCapabilities.nonTelevision(),
    ),
    initialLocation: initialLocation,
  );
}

bool _focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }
  final target = tester.element(find.byKey(ValueKey(key)));
  if (identical(focusContext, target)) {
    return true;
  }
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, target)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
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
