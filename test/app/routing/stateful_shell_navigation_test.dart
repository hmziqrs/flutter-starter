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

      // No page was pushed: the section swap is an in-place replace, so the
      // settings branch stays one page deep. A replaceNamed->pushNamed
      // regression would flip this to true and reintroduce a route transition.
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))).canPop(),
        isFalse,
      );

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
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.settingsPath,
        // /profile/edit is auth-required (C5 session gate); seed an authenticated
        // session so the pushNamed(updateProfile) overlay is not bounced.
        initialSession: _authenticatedSession,
      );

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
      // The Wave-6 pin-autolock tile grew the privacy-about section past the
      // 844-tall test viewport, so the Terms affordance sits below the fold.
      // Scroll it into view before tapping so the press reaches the handler
      // (mirrors tapVisible in integration_test_support.dart).
      await tester.ensureVisible(find.byKey(const ValueKey('settings-open-terms')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-open-terms')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('information-dialog')), findsOneWidget);

      // The dialog mounts on the ROOT navigator (useRootNavigator: true), so it
      // covers the bottom-nav chrome. Tapping the Pricing nav item is absorbed
      // by the dialog barrier and must NOT switch branches. With the old
      // branch-navigator placement the nav stayed tappable and this landed on
      // pricing-page.
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

      // The retained appearance branch keeps its ScrollPosition across the
      // round-trip (design item 3: "scroll and in-page state").
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

      // The router-level redirect normalized /settings/appearance to the query
      // form on entry, so the matched URI is /settings?section=appearance even
      // on cold start. Keeping the page key ValueKey('/settings') stable across
      // every settings page is what makes wide section switches run no platform
      // transition.
      final initialUri = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(initialUri.path, '/settings');
      expect(initialUri.queryParameters['section'], 'appearance');

      // Wide section swap targets /settings?section=language in place via
      // replaceNamed. The path staying /settings AND canPop staying false is
      // the load-bearing no-transition guard: a regression to a dedicated
      // /settings/language target would change the matched path/key and fire
      // the platform page transition; a replaceNamed->pushNamed regression
      // would flip canPop.
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

      // Resize to expanded. _pumpApp's _setViewport pins devicePixelRatio=1, so
      // physical==logical here. The redirect-normalized URI must survive the
      // layout rebuild: the wide SettingsPage reads ?section=appearance.
      tester.view.physicalSize = const Size(1024, 844);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'expanded layout at 1024px');
      expect(find.byKey(const ValueKey('accent-blue')), findsOneWidget);
      final expandedUri = GoRouterState.of(
        tester.element(find.byType(SettingsPage)),
      ).uri;
      expect(expandedUri.path, '/settings');
      expect(expandedUri.queryParameters['section'], 'appearance');

      // Resize back to compact. The appearance content is still reachable and
      // the settings branch is still one page deep (the redirect held across
      // both layout rebuilds).
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

      // Rapid-fire retargets with a sub-frame pump between taps: at 40ms the
      // 220ms cross-fade cannot finish mid-sequence, so each retarget starts
      // the implicit opacity animation from an intermediate value. This is the
      // real-world pattern that would expose a stale-opaque branch if the
      // container ever stopped retargeting from the current value. The taps
      // land on ForUI's footer gesture handler, not the icon render object
      // itself, so silence the benign hit-test warning.
      await tester.tap(
        compactNavIcon(FLucideIcons.badgeDollarSign),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(compactNavIcon(FLucideIcons.settings), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(compactNavIcon(FLucideIcons.house), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Settled destination is Home.
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      // Pin the no-stale-opaque guarantee through the real cross-fade plumbing:
      // read each branch wrapper's live opacity. Every branch stays mounted in
      // the Stack; at rest the active branch is fully opaque and the inactive
      // branches are fully transparent. AnimatedOpacity appears exactly once
      // per branch (the wrapper in crossFadingBranchContainer), so the
      // outermost ancestor is unambiguously the branch wrapper.
      //
      // The settings-branch anchor is the overview tile `settings-open-
      // appearance`, not `accent-blue`: this flow cold-starts at / and reaches
      // the settings branch via the bottom-nav (its defaultRoute is `/settings`
      // with no `?section=`), so compact layout renders the overview, not the
      // appearance detail. The overview tile is part of the settings branch
      // subtree and so is wrapped by the same branch AnimatedOpacity.
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
      dependencies: AppDependencies.inMemory(initialSession: initialSession),
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

/// Seeded authenticated session for auth-required destinations (/profile/edit,
/// C5 session gate). Deterministic placeholders; the gate checks isAuthenticated.
final _authenticatedSession = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);
