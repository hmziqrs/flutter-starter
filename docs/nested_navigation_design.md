# Nested navigation and cross-fade tab switches

This document records the design for migrating the application shell from a flat
`ShellRoute` to `StatefulShellRoute`, so that switching tabs cross-fades instead
of sliding and each tab keeps its own back-stack. It describes the change that is
about to be made; the code references are to the current `master`. The decision to
proceed was reached in this session; see *Recorded-decision reversal*.

## Why

Two problems share one root cause: the shell is a plain `ShellRoute`
(`lib/app/routing/app_router.dart:41-97`), which renders one shared navigator
across all chrome-bearing routes.

- **Tab switches slide on mobile.** Tabs are switched with `context.goNamed(...)`
  between sibling `GoRoute` leaves (`lib/app/shell/compact_app_shell.dart:25-29`,
  `lib/app/shell/expanded_app_shell.dart:49-61`). Because go_router renders those
  leaves as `MaterialPage`s, they inherit the global `nativePageTransitionsTheme`
  (`lib/shared/motion/app_page_transitions.dart:40-49`): on iOS that is the
  Cupertino horizontal slide, on Android the Material zoom. Both are *directional*
  transitions, which is the wrong affordance for a non-directional sibling tab
  swap. Desktop already cross-fades by coincidence of the platform map.
- **There are no per-tab back-stacks.** A shared navigator means switching tabs
  disposes the leaving page and loses its scroll and in-page state; navigating
  `settings → appearance` cannot survive a detour through another tab; and the
  "tap the active tab to pop to root" affordance is impossible. The settings
  sub-pages (`/settings/appearance`, `/settings/language`) are flat siblings
  precisely because the shell could not host a stack.

The target is `StatefulShellRoute`, which solves both at once: a custom branch
container cross-fades tab switches, and each branch owns an independent navigator.

## Verified go_router 17.3.0 constraints

These facts were confirmed against the pinned source
(`~/.pub-cache/.../go_router-17.3.0/lib/src/route.dart`) and govern the design.

- **`StatefulShellRoute.indexedStack` does not animate.** It hard-codes
  `_indexedStackContainerBuilder` (`route.dart:946`, default at `1668-1700`): a
  plain `IndexedStack` with `Offstage` + `TickerMode` children, no transition. To
  cross-fade, the **full** `StatefulShellRoute({...})` constructor must be used
  with a custom `navigatorContainerBuilder`.
- **The container owns the transition.** There is no `transitionBuilder`
  parameter on either constructor form; `navigatorContainerBuilder`
  (`ShellNavigationContainerBuilder = Widget Function(BuildContext,
  StatefulNavigationShell, List<Widget>)`, `route.dart:1208-1213`) is the only
  animation hook.
- **`AnimatedSwitcher` is wrong here.** The `List<Widget>` passed to the container
  are branch navigator proxies whose element lifecycle holds each branch's
  `Navigator` state (`route.dart:1561-1570`). A switcher that disposes the
  outgoing element would unmount that branch's navigator and silently destroy its
  route stack and scroll position. The container must keep every branch
  permanently mounted, mirroring the default `Offstage` + `TickerMode` scheme.
- **`goBranch(index, {initialLocation = false})`** restores a previously visited
  branch's last stack, or goes to its root when `initialLocation: true`
  (`route.dart:1276`, impl `1522`) — exactly the reset-on-retap affordance.
- **`shell.currentIndex` is correct on cold-start deep links** (e.g.
  `/settings/appearance` resolves to index 2), and `StatefulShellRoute.builder`
  receives the `StatefulNavigationShell` as its third argument (`route.dart:1011`).

## Target design

`StatefulShellRoute` replaces the plain `ShellRoute`. Three branches are ordered
home, pricing, settings so that `currentIndex` `0/1/2` matches the documented
`_selectedIndex` contract (`architecture.md:139`). The settings branch owns
`appearance` and `language` as nested child routes, giving settings a real per-tab
back-stack. go_router concatenates nested paths, so `/settings` + child
`'appearance'` stays `/settings/appearance` and the `AppRoutes.*Path` constants
and names are unchanged. Top-level full-screen flows (onboarding, paywall, auth,
profile edit, and the gated `/dev/*` routes) remain siblings of the shell so that
`pushNamed` from within a branch lands on the root navigator and overlays the
shell correctly.

```
StatefulShellRoute(
  restorationScopeId: 'appShell',
  builder: (context, state, shell) => AppShell(navigationShell: shell),
  navigatorContainerBuilder: crossFadingBranchContainer,
  branches: [
    StatefulShellBranch(routes: [ GoRoute home    path '/'           ]),
    StatefulShellBranch(routes: [ GoRoute pricing path '/pricing'    ]),
    StatefulShellBranch(routes: [
      GoRoute settings path '/settings' ( builder reads ?section=,
        routes: [
          GoRoute appearanceSettings path 'appearance',  // '/settings/appearance'
          GoRoute languageSettings   path 'language',    // '/settings/language'
        ],
      ),
    ]),
  ],
)
```

## Cross-fading branch container

The custom container is the riskiest single piece. It lives in a new
`lib/app/shell/cross_fading_branch_container.dart` and exposes a top-level
`crossFadingBranchContainer` matching the `ShellNavigationContainerBuilder`
signature, delegating to a `_CrossFadingBranchContainer` stateful widget.

The load-bearing invariants are:

- **Keep every branch mounted.** Each `children[i]` is wrapped in `Offstage` +
  `TickerMode(enabled: i == currentIndex)` regardless of index, exactly like the
  default container, so off-screen branch navigators and their scroll state
  survive.
- **Fade the incoming branch over the outgoing one.** An `AnimationController`
  with `duration: AppMotion.standard` driven through a `CurvedAnimation(curve:
  AppMotion.standardCurve)` runs `forward(from: 0)` from `didUpdateWidget` when
  `currentIndex` changes; the incoming branch is stacked on top inside a
  `FadeTransition`.
- **No fade on cold start or deep link.** The controller initializes to `value: 1`
  so the first-rendered branch (including a deep-linked settings sub-page) appears
  immediately. This matters for the resize test, which cold-starts at
  `/settings/appearance` (`test/app/app_test.dart:164`).
- **Honor reduce motion.** `MediaQuery.disableAnimationsOf(context)` collapses the
  swap to an instant, still-completing transition, satisfying the guardrail in
  `architecture.md:272`.

## Cross-tab callback audit

Under a shared shell, `goNamed` or `pushNamed` to another branch's root is wrong:
it replaces the stack or pushes a branch root onto the current branch's navigator
instead of switching tabs. Cross-tab navigation must go through `goBranch`. A
router-local helper captures the reset-on-retap behavior:

```dart
void _goTab(BuildContext context, int index) {
  final shell = StatefulNavigationShell.of(context);
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}
```

These callbacks are router-layer closures; feature pages stay go_router-free, so
no `feature_contracts.md` callback signature changes. The audit of the current
router callbacks is:

| Callback (`app_router.dart`) | Today | After migration |
|---|---|---|
| `home.onOpenPricing` (`:53`) | `goNamed(pricing)` | `_goTab(context, 1)` |
| `home.onOpenSettings` (`:54`) | `goNamed(settings)` | `_goTab(context, 2)` |
| `settings.onOpenPricing` (`:255`) | `pushNamed(pricing)` | `_goTab(context, 1)` |
| `settings.onOpenAppearance` (`:248`) | `pushNamed(appearance)` | unchanged — pushes onto the settings branch stack |
| `settings.onOpenLanguage` (`:249`) | `pushNamed(language)` | unchanged — settings branch stack |
| `_openSettingsSection` account/subscription/privacyAbout (`:268`) | `pushNamed(settings, ?section=)` | unchanged — settings branch stack |
| `home`/`settings` `onOpenProfile`, `onOpenLogin` (`:55`, `:253-254`) | `pushNamed(updateProfile\|login)` | unchanged — top-level root-navigator push |

## Shell and router changes

- **`lib/app/shell/cross_fading_branch_container.dart` (new).** The container
  described above. Depends only on `AppMotion` and `MediaQuery.disableAnimationsOf`.
- **`lib/app/shell/compact_app_shell.dart` and `expanded_app_shell.dart`.** Drop the
  `context.goNamed` switch in favor of a `required void Function(int) onSelectTab`
  callback. The footer `onChange` and each sidebar `onPress` call `onSelectTab`.
  `selectedIndex`, `child`, and `compactSidebar` are retained, as are the
  `compact-navigation`, `medium-shell`, `expanded-shell`, and `expanded-navigation`
  `ValueKey`s that tests depend on. The inner shells become go_router-agnostic;
  they are constructed only by `AppShell.build`, so this signature change is
  internal.
- **`lib/app/shell/app_shell.dart`.** The constructor becomes
  `AppShell({required StatefulNavigationShell navigationShell, super.key})`;
  `_selectedIndex` becomes `navigationShell.currentIndex`; `build` renders the
  shell as the body and passes `selectedIndex` plus an `onSelectTab` closure that
  calls `goBranch` with reset-on-retap. A new `AppShell.preview({required Widget
  child})` factory performs the same adaptive layout dispatch with a no-op tab
  callback for the dev-gallery chrome preview.
- **`lib/app/routing/app_router.dart`.** The `ShellRoute` block becomes the
  `StatefulShellRoute` block above; the three cross-tab callbacks move to
  `_goTab`. Everything else — top-level routes, `developmentToolsEnabled` gating,
  `errorBuilder`, and the `_settingsPage`, `_openSettingsSection`, and
  `_showInformationDialog` helpers — is unchanged, and `buildAppRouter`'s
  signature is unchanged so `initialLocation` deep links still resolve into a
  branch.

`lib/app/app.dart`, `lib/app/routing/app_routes.dart`,
`lib/app/routing/otp_purpose.dart`, every feature page, the const
`nativePageTransitionsTheme`, the `CrossFadePageTransitionsBuilder`, and the
`AppMotion` tokens are untouched.

## Contracts preserved and test impact

The frozen contracts in `plans/feature_contracts.md` are respected: no
`AppRoutes` constant, `otpLocation`, `OtpPurpose`, navigation callback signature,
shell `ValueKey`, or the `0/1/2` index contract changes, and the const
`nativePageTransitionsTheme` platform map stays exactly as pinned by
`test/shared/motion/app_page_transitions_test.dart`.

Tests expected to stay green without edits include the motion-map test (per-route
and branch transitions do not touch the const map or isolated builder),
`app_router_test.dart` (all fourteen production paths still resolve — nested paths
preserve `/settings/appearance`), `static_navigation_test.dart` (it asserts
destination state, not transitions), `motion_and_contrast_test.dart` (a gallery
case, no router), and both integration tests, which use bounded `pumpAppFrames`
and never `pumpAndSettle`, so a 220 ms fade cannot hang them.

One forced edit: `test/hardening/responsive/responsive_environment_test.dart:388`
constructs `AppShell(location: '/home', child: page)` for the gallery chrome
preview; it becomes `AppShell.preview(child: page)`. (`/home` was never a real
route, confirming this was always a layout preview.)

Three cases need verification during implementation but are expected to pass:
the `app_test.dart:164` resize flow (cold-start `/settings/appearance`, resize
through breakpoints, with no fade firing because the controller inits to value 1);
the `app_test.dart:67-105` back-and-recovery contract (a pushed unknown route from
a branch context must still surface `route-error-back` at the root navigator); and
the home quick-action cases in `static_navigation_test.dart`, now driven by
`goBranch`.

New coverage is required for the state-preservation invariant that goldens cannot
catch (the golden render path never goes through `AppShell`, and `baselines/` is
empty). A widget test should assert that switching branches mounts a
`FadeTransition` and that the outgoing branch's `Navigator` remains in the tree
mid-fade, mirroring the real-`App` test pattern
(`App(config, AppDependencies.inMemory(), initialLocation:)`).

## Recorded-decision reversal

`plans/initial_ui.md:174` records: *"Use a stateful shell only if separate
destination stacks must survive switching; do not add it merely because go_router
supports it."* This change reverses that decision. The justification is that the
application now has real settings sub-pages that benefit from a per-tab stack and
are flat siblings only because the plain shell could not host one; that future
tabs gain stacks for free by adding child routes to a branch; and that the
tab-switch transition is only correct when branch swaps are a distinct operation
from pushes. `plans/initial_ui.md` and the `routing` and `shell-adaptive-layout`
rows of `architecture.md` should be updated to record the new state as part of
this change.

## Verification

```bash
just analyze && just format-check
flutter test test/shared/motion/app_page_transitions_test.dart
flutter test test/app/routing/app_router_test.dart
flutter test test/app/routing/static_navigation_test.dart
flutter test test/app/app_test.dart
flutter test test/hardening/responsive/responsive_environment_test.dart
flutter test test/hardening/accessibility/motion_and_contrast_test.dart
flutter test test/app/shell/cross_fading_branch_container_test.dart
flutter test integration_test/production_routes_test.dart --dart-define-from-file=config/production.json
just test
just smoke macos
```

A visual check with `just watch 2.5` should confirm that tab switches cross-fade on
mobile with no slide, that `settings → appearance → pricing → back to settings`
restores the appearance page, and that tapping the active tab pops to its root.

## Risks

- **The branch container is the riskiest piece.** The rule "every branch stays
  mounted while fading" must hold; a switcher-style implementation would silently
  regress state preservation, and only the new widget test would catch it.
- **The callback audit must be complete.** Every `goNamed` or `pushNamed` to a
  branch root in `app_router.dart` must move to `goBranch`; grep for
  `AppRoutes.home|pricing|settings` to be sure.
- **Reduce-motion is honored for the new cross-fade only.** Route transitions are
  otherwise inconsistent app-wide (the iOS slide ignores reduce motion). This is a
  precedent, not a global fix, and is deliberately out of scope.
