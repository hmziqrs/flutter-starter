// Real-`App` coverage for the `StatefulShellRoute` migration documented in
// `docs/nested_navigation_design.md`. These tests exercise the live router +
// cross-fading shell (not gallery fixtures) to lock in the behaviors the
// migration introduced or depends on:
//  - per-branch back-stack persistence across tab switches (design item 3),
//  - reset-on-retap of the active tab and the system-Back edge it creates (4),
//  - compact push vs. wide `?section=` replace, including the no-animation guard
//    that prevents a silent regression to a dedicated `/settings/*` path (5),
//  - top-level `pushNamed` overlays preserving the branch stack (5e),
//  - the shell-lifetime boundary: `go` to a top-level flow resets every branch
//    stack on return, while a pushed overlay preserves them (6),
//  - the re-verified existing contracts: home quick actions select branches
//    through `goBranch`, a pushed unknown route still lands on the root
//    navigator with a working back action, and error/auth recovery still reach
//    Home through `goNamed` from outside the shell.
//
// The 220 ms cross-fade is finite, so `pumpAndSettle` is safe throughout.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  testWidgets(
    'branch state survives a compact tab switch when selection goes through goBranch',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);

      // Observable state on the appearance detail of the settings branch.
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('accent-blue')));
      await tester.pumpAndSettle();
      _expectAccent(tester, AppAccent.blue);

      // Switch to Pricing by tapping the bottom-nav item scoped to the compact
      // chrome (the home branch's `home-open-pricing` quick action uses a
      // different icon and is excluded by the `compact-navigation` scope).
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.badgeDollarSign),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

      // Switch back to Settings via the bottom-nav settings item.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();

      // Both the appearance route and its mutated state survived the round-trip.
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      _expectAccent(tester, AppAccent.blue);
    },
  );

  testWidgets(
    'retapping the active compact settings tab resets to the overview with no in-app back to the detail',
    (tester) async {
      await _pumpApp(tester, initialLocation: AppRoutes.appearanceSettingsPath);
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);

      // The Settings tab is the active branch (index 2); retapping it triggers
      // `goBranch(2, initialLocation: true)` which resets the branch to its
      // `defaultRoute` (`/settings` overview).
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('compact-navigation')),
          matching: find.byIcon(FLucideIcons.settings),
        ),
      );
      await tester.pumpAndSettle();

      // Reset landed on the overview, and the appearance detail is gone.
      expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-blue')), findsNothing);

      // System-Back contract: the overview is the settings branch root, so there
      // is no in-app pop back to the detail. Back has nowhere to go inside the
      // router (on Android it would leave the shell).
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
      // Overview is present; the account detail tile is not yet pushed.
      expect(find.byKey(const ValueKey('settings-open-account')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-open-profile')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('settings-open-account')));
      await tester.pumpAndSettle();
      // A push happened: the account section renders with the overview beneath.
      expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isTrue,
      );

      // System Back (router pop) returns to the overview.
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

      // Cold-start deep link renders the appearance detail only.
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      // No synthetic /settings overview was inserted below it: there is nothing
      // in-branch to pop back to.
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

      // Cold-start `/settings` defaults the wide pane to appearance.
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      expect(find.byKey(const ValueKey('locale-system')), findsNothing);
      final pathBefore = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri.path;
      expect(pathBefore, '/settings');

      // Selecting Language must target `/settings?section=language`, never a
      // dedicated `/settings/language` path. The path staying `/settings` is the
      // guard: a regression to a dedicated path would change the matched path,
      // reintroduce the platform page transition, and rebuild the pane.
      await tester.ensureVisible(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.tap(find.widgetWithText(FSidebarItem, 'Language'));
      await tester.pumpAndSettle();

      final uriAfter = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(uriAfter.path, '/settings');
      expect(uriAfter.queryParameters['section'], 'language');

      // The detail pane updated to the selected section in place.
      expect(find.byKey(const ValueKey('locale-system')), findsOneWidget);
      expect(find.byKey(const ValueKey('accent-blue')), findsNothing);

      // Duplicate selection of the currently-selected section is a route-aware
      // no-op: the URI is unchanged and no exception is thrown.
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
      await _pumpApp(tester, initialLocation: AppRoutes.settingsPath);

      // Build a settings branch stack: overview -> account detail.
      await tester.tap(find.byKey(const ValueKey('settings-open-account')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-profile')), findsOneWidget);

      // `pushNamed(updateProfile)` lands on the root navigator and overlays the
      // whole shell. The shell (with the account detail) stays mounted beneath.
      await tester.tap(find.byKey(const ValueKey('settings-open-profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
      // The account detail is preserved beneath the opaque profile overlay; it
      // is offstage while profile covers the shell, so look past offstage widgets.
      expect(
        find.byKey(const ValueKey('settings-open-profile'), skipOffstage: false),
        findsOneWidget,
      );

      // Dismiss the overlay. The account detail beneath survived — the branch
      // stack was preserved across the push/pop, unlike a `go` (see the
      // shell-lifetime test).
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

      // Leaving the shell with `go` unmounts it and disposes every branch state.
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(
        AppRoutes.onboardingPath,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

      // Return to the shell via the onboarding Skip callback, which reaches Home
      // through `goNamed` from outside the shell.
      await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      // Switching back to the Settings tab shows the branch root: the appearance
      // detail did NOT survive the `go`/return, because the shell was rebuilt.
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

      // Home -> Settings is now a branch selection, not a `goNamed` push.
      await tester.ensureVisible(find.byKey(const ValueKey('home-open-settings')));
      await tester.tap(find.byKey(const ValueKey('home-open-settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-open-appearance')), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
        reason: 'goBranch must not leave a push entry on the root stack',
      );

      // Home -> Pricing likewise selects branch index 1.
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

      // Pushing from a home-branch context puts the error page on the root
      // navigator (above the shell), so it exposes a working Back action.
      final homeContext = tester.element(find.byKey(const ValueKey('home-greeting')));
      unawaited(GoRouter.of(homeContext).push<void>('/not-a-route'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('route-error-back')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('route-error-back')));
      await tester.pumpAndSettle();

      // Back returns to the same branch (Home) that initiated the push.
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    },
  );
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String initialLocation,
  Size size = const Size(390, 844),
}) async {
  _setViewport(tester, size);
  await LocaleSettings.setLocale(AppLocale.en);
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      dependencies: AppDependencies.inMemory(),
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
);
