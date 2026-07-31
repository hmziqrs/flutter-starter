import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  testWidgets(
    'branch state survives a compact tab switch when selection goes through goBranch',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);

      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accent-blue')));
      await tester.pumpAndSettle();
      _expectAccent(tester, AppAccent.blue);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.badgeDollarSign),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      _expectAccent(tester, AppAccent.blue);
    },
  );

  testWidgets(
    'retapping the active compact settings tab resets to the overview with no in-app back to the detail',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-blue')), findsNothing);

      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'compact settings pushes a section detail and system back returns to the overview',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.settingsPath);
      expect(find.byKey(const ValueKey('settings-open-account')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-open-profile')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('settings-open-account')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isTrue,
      );

      GoRouter.of(tester.element(find.byType(SettingsPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-account')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-open-profile')), findsNothing);
    },
  );

  testWidgets(
    'direct deep link to /settings/appearance shows only the detail with no synthetic overview beneath',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);

      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'wide settings selection replaces the section in place without pushing a dedicated path',
    (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.settingsPath,
        size: const Size(1024, 844),
      );
      expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);

      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      expect(find.byKey(const ValueKey('locale-system')), findsNothing);
      final pathBefore = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri.path;
      expect(pathBefore, '/settings');

      await tester.ensureVisible(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.tap(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.pumpAndSettle();

      final uriAfter = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(uriAfter.path, '/settings');
      expect(uriAfter.queryParameters['section'], 'language');

      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
      );

      expect(find.byKey(const ValueKey('locale-system')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-blue')), findsNothing);

      await tester.ensureVisible(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.tap(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final uriDuplicate = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(uriDuplicate.toString(), uriAfter.toString());
    },
  );

  testWidgets(
    'pushed top-level overlay preserves the settings branch stack beneath it',
    (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.settingsPath,
        initialSession: _authenticatedSession,
      );

      await tester.tap(find.byKey(const ValueKey('settings-open-account')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-open-profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings-open-profile'), skipOffstage: false),
        findsOneWidget,
      );

      GoRouter.of(tester.element(find.byKey(const ValueKey('profile-save')))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-save')), findsNothing);
      expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);
    },
  );

  testWidgets(
    'go to a top-level flow resets every branch stack on return (shell-lifetime boundary)',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);

      GoRouter.of(tester.element(find.byType(Navigator).first)).go(
        AppRoutes.onboardingPath,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-blue')), findsNothing);
    },
  );

  testWidgets(
    'home quick actions select branches through goBranch without pushing the root stack',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.homePath);
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('home-open-settings')));
      await tester.tap(find.byKey(const ValueKey('home-open-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
        reason: 'goBranch must not leave a push entry on the root stack',
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.badgeDollarSign),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byKey(const ValueKey('pricing-page')))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'pushed unknown route from a branch lands on the root navigator and pops back to the same branch',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.homePath);

      final homeContext = tester.element(find.byKey(const ValueKey('home-greeting')));
      unawaited(GoRouter.of(homeContext).push<void>('/not-a-route'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route-error-back')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('route-error-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    },
  );

  testWidgets(
    'expanded sidebar nav items select the correct branch via onSelectTab',
    (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.homePath,
        size: const Size(1024, 844),
      );
      expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      final navigationRect = tester.getRect(
        find.byKey(const ValueKey('expanded-navigation')),
      );
      final brandRect = tester.getRect(
        find.byKey(const ValueKey('expanded-navigation-brand')),
      );
      final homeRect = tester.getRect(
        find.byKey(const ValueKey('expanded-navigation-home')),
      );
      final pricingRect = tester.getRect(
        find.byKey(const ValueKey('expanded-navigation-pricing')),
      );
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('expanded-navigation-settings')),
      );
      final homeIconRect = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('expanded-navigation-home')),
          matching: find.byIcon(FLucideIcons.house),
        ),
      );

      expect(homeRect.left, greaterThan(navigationRect.left));
      expect(
        navigationRect.right - homeRect.right,
        closeTo(homeRect.left - navigationRect.left, 0.01),
      );
      expect(brandRect.left, closeTo(homeIconRect.left, 0.01));
      expect(pricingRect.top - homeRect.bottom, greaterThan(0));
      expect(
        settingsRect.top - pricingRect.bottom,
        closeTo(pricingRect.top - homeRect.bottom, 0.01),
      );

      Finder sidebarItem(IconData icon) => find.descendant(
        of: find.byKey(const ValueKey('expanded-navigation')),
        matching: find.byIcon(icon),
      );

      await tester.tap(sidebarItem(FLucideIcons.badgeDollarSign));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

      await tester.tap(sidebarItem(FLucideIcons.settings));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);

      await tester.tap(sidebarItem(FLucideIcons.house));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    },
  );

  testWidgets(
    'an open information dialog overlays the shell chrome and blocks a tab switch',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.settingsPath);
      await tester.tap(find.byKey(const ValueKey('settings-open-privacy-about')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('settings-open-terms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-open-terms')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.badgeDollarSign),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
    },
  );

  testWidgets(
    'appearance scroll position survives a compact tab round-trip',
    (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.appearanceSettingsPath,
        size: const Size(390, 600),
      );
      ScrollableState appearanceScroll() =>
          Scrollable.of(tester.element(find.byKey(const ValueKey('font-scale-slider'))));
      final scrollState = appearanceScroll();
      scrollState.position.jumpTo(240);
      await tester.pumpAndSettle();
      final offset = scrollState.position.pixels;
      expect(offset, greaterThan(0));

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.badgeDollarSign),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();

      final scrollStateAfter = appearanceScroll();
      expect(scrollStateAfter.position.pixels, offset);
    },
  );

  testWidgets(
    'cold-start /settings/appearance wide section switch runs no transition (redirect normalized the deep link)',
    (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.appearanceSettingsPath,
        size: const Size(1024, 844),
      );
      expect(find.byKey(const ValueKey('expanded-shell')), findsOneWidget);

      final initialUri = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(initialUri.path, '/settings');
      expect(initialUri.queryParameters['section'], 'appearance');

      await tester.ensureVisible(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.tap(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.pumpAndSettle();

      final uriAfter = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(uriAfter.path, '/settings');
      expect(uriAfter.queryParameters['section'], 'language');
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
        reason: 'replaceNamed in place leaves no push entry to pop',
      );
    },
  );

  testWidgets(
    'cold-start /settings/appearance survives a compact->expanded->compact resize round-trip',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
        reason: 'redirect left no in-branch stack to pop',
      );

      tester.view.physicalSize = const Size(1024, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'expanded layout at 1024px');
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      final expandedUri = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(expandedUri.path, '/settings');
      expect(expandedUri.queryParameters['section'], 'appearance');

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'rapid home->pricing->settings->home retarget settles on home with the other branches faded out',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.homePath);
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      Finder compactNavIcon(IconData icon) => find.descendant(
        of: find.byKey(const ValueKey('compact-navigation')),
        matching: find.byIcon(icon),
      );

      // warnIfMissed:false: taps land on ForUI's footer gesture handler, not the icon.
      await tester.tap(
        compactNavIcon(FLucideIcons.badgeDollarSign),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(compactNavIcon(FLucideIcons.settings), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(compactNavIcon(FLucideIcons.house), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      double branchOpacity(Key anchor) => tester
          .renderObject<RenderAnimatedOpacity>(
            find
                .ancestor(
                  of: find.byKey(anchor),
                  matching: find.byType(AnimatedOpacity),
                )
                .first,
          )
          .opacity
          .value;

      expect(
        branchOpacity(const ValueKey('home-greeting')),
        1.0,
        reason: 'home branch is the active branch at rest',
      );
      expect(
        branchOpacity(const ValueKey('pricing-page')),
        0.0,
        reason: 'pricing branch faded out at rest',
      );
      expect(
        branchOpacity(const ValueKey('settings-open-appearance')),
        0.0,
        reason: 'settings branch faded out at rest',
      );
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String initialLocation,
  Size size = const Size(390, 844),
  AuthSession? initialSession,
}) async {
  _setViewport(tester, size);
  await LocaleSettings.setLocale(AppLocale.en);
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      dependencies: AppDependencies.inMemory(
        initialSession: initialSession,
        dismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
      ),
      initialLocation: initialLocation,
    ),
  );
  await tester.pumpAndSettle();
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void _expectAccent(WidgetTester tester, AppAccent accent) {
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const ValueKey('accent-blue'))),
  );
  expect(container.read(settingsControllerProvider).accent, accent);
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
