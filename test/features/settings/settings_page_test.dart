import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_section.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';

void main() {
  testWidgets('compact overview exposes every settings section and account flow', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      _app(initialLocation: '/settings', initialSession: _authenticatedSession),
    );
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
    // Authenticated: the quiet destructive sign-out row is offered inline.
    expect(find.byKey(const ValueKey('settings-sign-out')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-open-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Update profile'), findsOneWidget);
  });

  testWidgets('anonymous account section offers sign-in as a row, never a forced redirect', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(_app(initialLocation: '/settings?section=account'));
    await tester.pumpAndSettle();

    // Anonymous: profile editing still opens and sign-in is a quiet row; there
    // is no sign-out to offer and the page never forces authentication.
    expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-open-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-sign-out')), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('You are signed out.'), findsOneWidget);

    final router = GoRouter.of(tester.element(find.byKey(const ValueKey('settings-open-login'))));
    await tester.tap(find.byKey(const ValueKey('settings-open-login')));
    await tester.pumpAndSettle();
    // The login flow opens over settings and stays dismissable — sign-in is
    // offered, never forced over the anonymous session.
    expect(find.byKey(const ValueKey('auth-login-form')), findsOneWidget);
    expect(router.canPop(), isTrue, reason: 'sign-in is pushed, not forced over settings');
  });

  testWidgets('subscription and privacy actions provide honest destinations', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(_app(initialLocation: '/settings?section=subscription'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-view-pricing')));
    await tester.pumpAndSettle();
    expect(find.text('Plans for the way you work'), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.text('Plans for the way you work'))).canPop(),
      isFalse,
    );

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
    await tester.ensureVisible(find.byKey(const ValueKey('settings-open-terms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-open-terms')).hitTestable());
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

  testWidgets('expanded settings and spacing labels remain localized', (tester) async {
    _setViewport(tester, const Size(1024, 844));
    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(_app(initialLocation: '/settings/appearance'));
    await tester.pumpAndSettle();

    // The sidebar starts collapsed to the icon rail; the toggle expands it.
    expect(find.byKey(const ValueKey('medium-shell')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expanded-navigation-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);

    expect(find.text('واسع'), findsOneWidget);
    expect(find.text('relaxed'), findsNothing);
    expect(Directionality.of(tester.element(find.text('واسع'))), TextDirection.rtl);
  });

  testWidgets('appearance spacing and radius variants render and persist', (tester) async {
    _setViewport(tester, const Size(1024, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    final store = InMemorySettingsStore();
    await tester.pumpWidget(
      _app(
        initialLocation: '/settings/appearance',
        dependencies: AppDependencies.inMemory(settingsStore: store),
      ),
    );
    await tester.pumpAndSettle();

    for (final variant in AppSpacingVariant.values) {
      expect(find.byKey(ValueKey('spacing-${variant.name}')), findsOneWidget);
    }
    for (final variant in AppRadiusVariant.values) {
      expect(find.byKey(ValueKey('radius-${variant.name}')), findsOneWidget);
    }

    final spacingRelaxed = find.byKey(const ValueKey('spacing-relaxed'));
    await tester.ensureVisible(spacingRelaxed);
    await tester.pumpAndSettle();
    await tester.tap(spacingRelaxed.hitTestable());
    await tester.pumpAndSettle();
    final radiusSharp = find.byKey(const ValueKey('radius-sharp'));
    await tester.ensureVisible(radiusSharp);
    await tester.pumpAndSettle();
    await tester.tap(radiusSharp.hitTestable());
    await tester.pumpAndSettle();

    expect(await store.readString('appearance.spacing'), AppSpacingVariant.relaxed.name);
    expect(await store.readString('appearance.radius'), AppRadiusVariant.sharp.name);
  });

  testWidgets('privacy-about analytics opt-in toggle persists the SecureStore key', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await LocaleSettings.setLocale(AppLocale.en);
    final secureStore = InMemorySecureStore();
    await tester.pumpWidget(
      _app(
        initialLocation: '/settings?section=privacy-about',
        dependencies: AppDependencies.inMemory(secureStore: secureStore),
      ),
    );
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final toggle = find.byKey(const ValueKey('settings-toggle-analytics'));
    await tester.ensureVisible(toggle);
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.widget<FSwitch>(toggle).value, isFalse);
    expect(secureStore.snapshot.containsKey(analyticsOptInKey), isFalse);

    await tester.tap(toggle.hitTestable());
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.widget<FSwitch>(toggle).value, isTrue);
    expect(secureStore.snapshot[analyticsOptInKey], 'true');
  });

  testWidgets('settings sections use horizontal tabs at medium and a section column at expanded', (
    tester,
  ) async {
    _setViewport(tester, const Size(640, 844));
    await LocaleSettings.setLocale(AppLocale.en);

    const sectionKeys = [
      ValueKey('settings-wide-appearance'),
      ValueKey('settings-wide-language'),
      ValueKey('settings-wide-accessibility'),
      ValueKey('settings-wide-account'),
      ValueKey('settings-wide-subscription'),
      ValueKey('settings-wide-privacy-about'),
    ];

    // Medium: the sections are a horizontal segmented tab row above the
    // content — laid out left-to-right with the appearance section picked.
    await tester.pumpWidget(_app(initialLocation: '/settings/appearance'));
    await tester.pumpAndSettle();
    final segmented = find.byKey(const ValueKey('settings-wide-navigation'));
    expect(segmented, findsOneWidget);
    for (final key in sectionKeys) {
      expect(find.byKey(key), findsOneWidget);
    }
    final tabRects = sectionKeys.map((key) => tester.getRect(find.byKey(key))).toList();
    for (var index = 1; index < tabRects.length; index++) {
      expect(tabRects[index].left, greaterThan(tabRects[index - 1].left));
    }
    expect(
      tester.widget<AppSegmented<String>>(segmented).value,
      SettingsSection.appearance.name,
    );

    // Expanded: the section column remains, with equal vertical gaps and the
    // active section selected.
    tester.view.physicalSize = const Size(1024, 844);
    await tester.pumpWidget(_app(initialLocation: '/settings/appearance'));
    await tester.pumpAndSettle();

    final itemRects = sectionKeys.map((key) => tester.getRect(find.byKey(key))).toList();
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

  testWidgets('wide settings navigation scrolls instead of overflowing at maximum font scale', (
    tester,
  ) async {
    _setViewport(tester, const Size(640, 400));
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      _app(
        initialLocation: '/settings/appearance',
        dependencies: AppDependencies.inMemory(
          settingsStore: InMemorySettingsStore(seed: {'appearance.font_scale': '1.60'}),
        ),
      ),
    );
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('settings-wide-navigation')), findsOneWidget);
  });
}

Widget _app({
  required String initialLocation,
  AuthSession? initialSession,
  PlatformCapabilities? capabilities,
  AppDependencies? dependencies,
}) {
  return App(
    config: _developmentConfig,
    dependencies:
        dependencies ??
        AppDependencies.inMemory(
          initialSession: initialSession,
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
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

final _authenticatedSession = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
