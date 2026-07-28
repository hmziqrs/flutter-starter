import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/startup/startup_error_view.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  const localeCases = [
    (
      locale: AppLocale.en,
      title: 'Welcome, Alex',
      tabSemantics: 'Tab 1 of 3',
      direction: TextDirection.ltr,
    ),
    (
      locale: AppLocale.ar,
      title: 'مرحبًا، Alex',
      tabSemantics: 'علامة التبويب 1 من 3',
      direction: TextDirection.rtl,
    ),
    (
      locale: AppLocale.zhHans,
      title: '欢迎，Alex',
      tabSemantics: '第 1 个标签，共 3 个',
      direction: TextDirection.ltr,
    ),
  ];

  for (final localeCase in localeCases) {
    testWidgets('renders the root and ForUI localization for ${localeCase.locale}', (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await LocaleSettings.setLocale(localeCase.locale);

      await tester.pumpWidget(
        App(
          config: _developmentConfig,
          dependencies: AppDependencies.inMemory(),
        ),
      );
      await tester.pumpAndSettle();

      final title = find.text(localeCase.title);
      expect(title, findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == localeCase.tabSemantics,
          description: 'ForUI localized tab-position semantics',
        ),
        findsOneWidget,
      );
      expect(Directionality.of(tester.element(title)), localeCase.direction);
    });
  }

  testWidgets('unknown cold-start route recovers without an invalid back action', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: '/not-a-route',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We could not open that page'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-error-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-error-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('route-error-home')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Alex'), findsOneWidget);
  });

  testWidgets('unknown pushed route offers a working back action', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: AppDependencies.inMemory(),
      ),
    );
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byKey(const ValueKey('home-open-settings')));
    unawaited(GoRouter.of(homeContext).push<void>('/not-a-route'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('route-error-back')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('route-error-back')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Alex'), findsOneWidget);
  });

  testWidgets('development diagnostics route is physically absent in production', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.diagnosticsPath,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Development diagnostics'), findsNothing);
    expect(find.text('We could not open that page'), findsOneWidget);

    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.diagnosticsPath,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Development diagnostics'), findsOneWidget);
  });

  testWidgets('development screen gallery is real and physically absent in production', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.en);
    _setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.developmentScreensPath,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We could not open that page'), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-search')), findsNothing);

    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.developmentScreensPath,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gallery-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-preview-viewport')), findsOneWidget);
    expect(find.text('Onboarding'), findsWidgets);
  });

  testWidgets('live resize preserves the route and settings state at breakpoint boundaries', (
    tester,
  ) async {
    await LocaleSettings.setLocale(AppLocale.en);
    _setViewport(tester, const Size(639, 844));
    await tester.pumpWidget(
      App(
        config: _developmentConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.appearanceSettingsPath,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'compact layout at 639px');

    expect(find.byKey(const ValueKey('compact-navigation')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('accent-blue')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'compact theme update at 639px');
    _expectBlueAccent(tester);

    tester.view.physicalSize = const Size(640, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'medium layout at 640px');
    expect(find.byKey(const ValueKey('medium-shell')), findsOneWidget);
    expect(find.text('Appearance'), findsWidgets);
    _expectBlueAccent(tester);

    tester.view.physicalSize = const Size(1023, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'medium layout at 1023px');
    expect(find.byKey(const ValueKey('medium-shell')), findsOneWidget);
    _expectBlueAccent(tester);

    tester.view.physicalSize = const Size(1024, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'expanded layout at 1024px');
    expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);
    expect(find.text('Appearance'), findsWidgets);
    _expectBlueAccent(tester);
  });

  testWidgets('startup error exposes only a safe diagnostic identifier', (tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(diagnosticId: 'STARTUP-CONFIG'),
    );

    expect(find.textContaining('STARTUP-CONFIG'), findsOneWidget);
    expect(find.textContaining('password='), findsNothing);
    expect(find.byKey(const ValueKey('startup-retry')), findsNothing);
  });

  testWidgets('startup error invokes retry when recovery is available', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(
      StartupErrorApp(
        diagnosticId: 'STARTUP-UNKNOWN',
        onRetry: () => retryCount += 1,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('startup-retry')));
    await tester.pumpAndSettle();

    expect(retryCount, 1);
  });
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _expectBlueAccent(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const ValueKey('accent-blue'))),
  );
  expect(container.read(settingsControllerProvider).accent, AppAccent.blue);
}
