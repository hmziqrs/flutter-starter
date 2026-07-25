# Nested navigation and cross-fade tab switches

This document records the design for migrating the application shell from a flat
`ShellRoute` to `StatefulShellRoute`, so that switching tabs cross-fades instead
of sliding and each tab keeps its own back-stack. It describes the change that is
about to be made; the code references are to the current `master`. The decision to
proceed was reached in this session; see *Recorded-decision update*.

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
  swap. Desktop already cross-fades by deliberate policy in
  `app_page_transitions.dart`; the new container makes tab behavior independent of
  the per-route platform transition map.
- **There are no per-tab back-stacks.** A shared navigator means switching tabs
  disposes the leaving page and loses its scroll and in-page state; navigating
  `settings → appearance` cannot survive a detour through another tab. A plain
  `ShellRoute` can host one stack—the existing `pushNamed` calls already put
  settings pages on it—but it cannot retain separate parallel stacks while a tab
  switch replaces that shared route configuration. Navigating the active tab to
  its root is possible today; what is missing is the combination of reset-on-retap
  and restoring every *other* tab's last stack.

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
- **Switching only the active child is wrong here.** The `List<Widget>` passed to
  the container contains stable branch navigator proxies whose element lifecycle
  retains each loaded branch's `Navigator` state (`route.dart:1561-1570`). An
  `AnimatedSwitcher` around only the active child would eventually unmount the
  outgoing proxy and destroy that branch's route stack and scroll position. The
  container must keep every proxy in one stable child list and animate visibility
  without removing children.
- **`goBranch(index, {initialLocation = false})`** restores a previously visited
  branch's last stack, or goes to its root when `initialLocation: true`
  (`route.dart:1276`, impl `1522`) — exactly the reset-on-retap affordance.
- **`shell.currentIndex` is correct on cold-start deep links** (e.g.
  `/settings/appearance` resolves to index 2), and `StatefulShellRoute.builder`
  receives the `StatefulNavigationShell` as its third argument (`route.dart:1011`).
- **Branch persistence is not Flutter restoration.** `StatefulShellRoute` retains
  loaded branch navigators for the lifetime of the live router without a
  `restorationScopeId`. Process-death restoration remains deferred under the
  project's existing restoration policy.

## Target design

`StatefulShellRoute` replaces the plain `ShellRoute`. Three branches are ordered
home, pricing, settings so that `currentIndex` `0/1/2` matches the documented
`_selectedIndex` contract under `shell-adaptive-layout` in
`architecture.md`. The settings branch owns the existing settings routes as
siblings on the same branch navigator. `pushNamed` therefore creates the compact
`settings → detail` stack without introducing relative path literals or changing
cold-start deep-link history. Direct `/settings/appearance` still opens only that
route; it does not synthesize `/settings` beneath it.

Top-level full-screen flows (onboarding, paywall, auth, profile edit, and the
gated `/dev/*` routes) remain siblings of the shell. A `pushNamed` from a branch
to one of those routes lands on the root navigator and overlays the whole shell.

```
StatefulShellRoute(
  builder: (context, state, shell) => AppShell(navigationShell: shell),
  navigatorContainerBuilder: crossFadingBranchContainer,
  branches: [
    StatefulShellBranch(routes: [
      GoRoute home path AppRoutes.homePath,
    ]),
    StatefulShellBranch(routes: [
      GoRoute pricing path AppRoutes.pricingPath,
    ]),
    StatefulShellBranch(routes: [
      GoRoute settings           path AppRoutes.settingsPath,
      GoRoute appearanceSettings path AppRoutes.appearanceSettingsPath,
      GoRoute languageSettings   path AppRoutes.languageSettingsPath,
    ]),
  ],
)
```

## Cross-fading branch container

The custom container is the riskiest single piece. It lives in a new
`lib/app/shell/cross_fading_branch_container.dart` and exposes a top-level
`crossFadingBranchContainer` matching the `ShellNavigationContainerBuilder`
signature, delegating to a `_CrossFadingBranchContainer` widget.

The load-bearing invariants are:

- **Keep every branch proxy mounted in stable order.** A
  `Stack(fit: StackFit.expand)` always contains every `children[i]`; switching
  tabs never removes or reorders a proxy. An unvisited branch may still be a
  lightweight proxy until go_router lazily creates its navigator, but every
  loaded navigator remains mounted.
- **Cross-fade both branches.** Each child is wrapped in `AnimatedOpacity` with
  opacity `1` for `currentIndex` and `0` otherwise, duration
  `AppMotion.standard`, and curve `AppMotion.standardCurve`. The outgoing opacity
  falls while the incoming opacity rises, so the old branch remains painted
  throughout the handoff instead of being hidden by `Offstage`.
- **Only the current branch is interactive.** Every wrapper also uses
  `IgnorePointer`, `ExcludeFocus`, `ExcludeSemantics`, and
  `TickerMode(enabled: index == currentIndex)`. The current branch becomes the
  sole interactive and accessible branch as soon as routing selects it; fading
  outgoing content remains visual only.
- **No fade on cold start or deep link.** `AnimatedOpacity` initializes its tween
  from the first supplied opacity, so the initial current branch—including a
  deep-linked settings page—appears immediately.
- **Rapid switches retarget from current opacity.** Implicit opacity animations
  naturally retarget A→B→C without manually tracking a previous index, exposing a
  stale branch, or resetting an `AnimationController`.
- **Honor reduce motion.** When `MediaQuery.disableAnimationsOf(context)` is
  true, every wrapper receives `Duration.zero`; the new branch is visible and
  interactive in the same frame. This follows the custom-animation guardrail
  under “Where do I...” in `architecture.md`.

The intended structure is:

```dart
Widget crossFadingBranchContainer(
  BuildContext context,
  StatefulNavigationShell shell,
  List<Widget> children,
) {
  return _CrossFadingBranchContainer(
    currentIndex: shell.currentIndex,
    children: children,
  );
}

class _CrossFadingBranchContainer extends StatelessWidget {
  const _CrossFadingBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.standard;

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (index, child) in children.indexed)
          AnimatedOpacity(
            opacity: index == currentIndex ? 1 : 0,
            duration: duration,
            curve: AppMotion.standardCurve,
            child: IgnorePointer(
              ignoring: index != currentIndex,
              child: ExcludeFocus(
                excluding: index != currentIndex,
                child: ExcludeSemantics(
                  excluding: index != currentIndex,
                  child: TickerMode(
                    enabled: index == currentIndex,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

## Cross-tab callback audit

From a context below the stateful shell, `goNamed` or `pushNamed` to another
branch's root is the wrong abstraction: it changes a location or pushes a page
instead of selecting and restoring the target branch. In-shell tab switches must
go through `goBranch`. A router-local helper captures the reset-on-retap behavior:

```dart
void _goTab(BuildContext context, int index) {
  final shell = StatefulNavigationShell.of(context);
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}
```

`_goTab` is valid only for callbacks whose `BuildContext` is below a branch
navigator. Top-level onboarding, paywall, auth, and route-error callbacks have no
`StatefulNavigationShell` ancestor and continue to use `goNamed`; using `_goTab`
there would fail. These remain router-layer closures, so feature pages stay
go_router-free and no `feature_contracts.md` callback signature changes.

The audit of current callbacks is:

| Callback (`app_router.dart`) | Today | After migration |
|---|---|---|
| `home.onOpenPricing` (`:53`) | `goNamed(pricing)` | `_goTab(context, 1)` |
| `home.onOpenSettings` (`:54`) | `goNamed(settings)` | `_goTab(context, 2)` |
| `settings.onOpenPricing` (`:255`) | `pushNamed(pricing)` | `_goTab(context, 1)` |
| `settings.onOpenAppearance` (`:248`) | `pushNamed(appearance)` | `_openSettingsDestination(appearance)` |
| `settings.onOpenLanguage` (`:249`) | `pushNamed(language)` | `_openSettingsDestination(language)` |
| `_openSettingsSection` account/subscription/privacyAbout (`:268`) | `pushNamed(settings, ?section=)` | delegates to `_openSettingsDestination(settings, ?section=)` |
| `home`/`settings` `onOpenProfile`, `onOpenLogin` (`:55`, `:253-254`) | `pushNamed(updateProfile\|login)` | unchanged — top-level root-navigator push |
| Onboarding/paywall/auth success callbacks to Home | `goNamed(home)` | unchanged — caller is outside the shell |
| `RouteErrorPage.onHome` (`:323`) | `goNamed(home)` | unchanged — must work without a shell ancestor |

### Settings branch navigation policy

The settings branch intentionally distinguishes compact drill-in navigation from
wide pane selection:

- **Compact:** opening a section from `/settings` uses `pushNamed`, so system Back
  returns to the overview. A direct cold-start `/settings/appearance` retains the
  current behavior: no synthetic overview page is inserted below it.
- **Medium and expanded:** selecting a section uses `replaceNamed`, which keeps
  one section page at the top of the settings branch, reuses its page key, and
  runs no directional page transition. Repeatedly selecting the exact current
  path and query is a no-op.
- **Resize:** navigation history is not synthesized or discarded merely because
  the layout changes. A section selected while wide therefore remains one page
  when resized to compact; a compact overview/detail stack remains a stack when
  resized wide.

The router can implement this without changing `SettingsPage` callbacks. The
callback context is below `AppLayoutScope`, so a helper reads the nearest
`appLayoutClassProvider`, compares the current URI with the named target, then
pushes or replaces:

```dart
void _openSettingsDestination(
  BuildContext context,
  String name, {
  Map<String, dynamic> queryParameters = const {},
}) {
  final target = Uri.parse(
    context.namedLocation(name, queryParameters: queryParameters),
  );
  if (GoRouterState.of(context).uri == target) return;

  final layoutClass = ProviderScope.containerOf(
    context,
  ).read(appLayoutClassProvider);

  if (layoutClass == AppLayoutClass.compact) {
    unawaited(
      context.pushNamed<void>(
        name,
        queryParameters: queryParameters,
      ),
    );
    return;
  }

  context.replaceNamed(name, queryParameters: queryParameters);
}
```

## Shell and router changes

- **`lib/app/shell/cross_fading_branch_container.dart` (new).** The container
  described above. It uses the Flutter widget primitives listed in the container
  invariants plus `AppMotion` and `MediaQuery.disableAnimationsOf`.
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
  `_goTab`. `_settingsPage` and `_openSettingsSection` use the layout-aware
  `_openSettingsDestination` policy above. Top-level routes,
  `developmentToolsEnabled` gating, `errorBuilder`, and
  `_showInformationDialog` are unchanged, and `buildAppRouter`'s signature is
  unchanged so `initialLocation` deep links still resolve into a branch.

`lib/app/app.dart`, `lib/app/routing/app_routes.dart`,
`lib/app/routing/otp_purpose.dart`, every feature page, the const
`nativePageTransitionsTheme`, the `CrossFadePageTransitionsBuilder`, and the
`AppMotion` tokens are untouched. No restoration scope is added; live branch
persistence does not activate the separately deferred Flutter restoration work.

## Contracts preserved and test impact

The frozen contracts in `plans/feature_contracts.md` are respected: no
`AppRoutes` constant, `otpLocation`, `OtpPurpose`, navigation callback signature,
shell `ValueKey`, or the `0/1/2` index contract changes, and the const
`nativePageTransitionsTheme` platform map stays exactly as pinned by
`test/shared/motion/app_page_transitions_test.dart`.

Tests expected to stay green without edits include the motion-map test (per-route
and branch transitions do not touch the const map or isolated builder),
`app_router_test.dart` (all fourteen production paths and their direct-entry
history remain unchanged), `static_navigation_test.dart` (it asserts destination
state, not transitions), `motion_and_contrast_test.dart` (a gallery case, no
router), and both integration tests, which use bounded `pumpAppFrames` and never
`pumpAndSettle`, so a 220 ms fade cannot hang them.

One forced edit: `test/hardening/responsive/responsive_environment_test.dart:388`
constructs `AppShell(location: '/home', child: page)` for the gallery chrome
preview; it becomes `AppShell.preview(child: page)`. (`/home` was never a real
route, confirming this was always a layout preview.)

Existing contracts that must be explicitly re-verified during implementation:

- The cold-start `/settings/appearance` resize flow in `app_test.dart` traverses
  every breakpoint without firing a tab fade or changing history.
- A pushed unknown route from a branch context still places the error page on the
  root navigator, exposes `route-error-back`, and pops back to the same branch.
- Home quick actions switch branches through `goBranch`; auth and error recovery
  still reach Home through `goNamed` from outside the shell.
- Compact settings pushes details and returns to its overview, while wide
  settings replaces sections without duplicate history or route animation.

New coverage is required because the canonical golden harness renders gallery
pages directly rather than through `AppShell`; its existing thirteen baseline
images cannot exercise branch navigation:

1. A focused container test must inspect every `AnimatedOpacity` at the initial,
   midpoint, and settled frames. Mid-fade, outgoing and incoming branches must
   both be non-offstage and have complementary opacity; inactive branches remain
   mounted but have pointer, focus, semantics, and tickers disabled.
2. The same test must cover `disableAnimations`, verify an immediate swap, and
   retarget A→B→C before the first fade settles.
3. A real-`App` test must push `settings → appearance`, mutate observable widget
   or scroll state, switch to Pricing, settle, switch back to Settings, and assert
   the appearance route and state survived.
4. The real-`App` test must retap the active Settings destination, assert a reset
   to `/settings`, and verify the system Back contract.
5. Router tests must cover compact push versus wide replace, duplicate-selection
   no-op, direct deep-link Back behavior, top-level overlay placement, and pushed
   error-page recovery.

## Recorded-decision update

The route rules in `plans/initial_ui.md` say to use a stateful shell only when
separate destination stacks must survive switching. This change now satisfies
that condition; it does not adopt `StatefulShellRoute` merely because the package
supports it. Settings has a real stack that must survive visits to Home or
Pricing, and tab swaps need a transition distinct from pushes within a branch.
The routes may remain flat siblings inside their owning branch because a plain
shell's limitation is parallel-stack persistence, not the ability to host any
stack.

`plans/initial_ui.md` and the `routing` and `shell-adaptive-layout` sections of
`architecture.md` should be updated with the new state as part of implementation.
The separate decision to defer Flutter route/draft restoration remains unchanged.

## Verification

```bash
just analyze && just format-check
flutter test test/shared/motion/app_page_transitions_test.dart
flutter test test/app/routing/app_router_test.dart
flutter test test/app/routing/static_navigation_test.dart
flutter test test/app/routing/stateful_shell_navigation_test.dart
flutter test test/app/app_test.dart
flutter test test/hardening/responsive/responsive_environment_test.dart
flutter test test/hardening/accessibility/motion_and_contrast_test.dart
flutter test test/app/shell/cross_fading_branch_container_test.dart
flutter test test/features/settings/settings_page_test.dart
just test
just smoke macos
just test-prod-routes macos
```

A visual check with `just watch 2.5` should confirm that tab switches cross-fade on
mobile with no slide or blank frame; tapping Settings after
`settings → appearance → pricing` restores Appearance; tapping Settings again
resets it to the settings root; rapid tab taps never reveal a stale branch.

## Risks

- **The branch container is the riskiest piece.** Every loaded branch must stay
  mounted, both transition participants must remain painted, and only the current
  branch may participate in input, focus, semantics, or ticking. The focused
  container test and the completed round-trip state test cover different failure
  modes; neither replaces the other.
- **The callback audit is context-sensitive.** Only in-shell actions whose intent
  is “select another tab” move to `goBranch`. Top-level onboarding, auth, paywall,
  and error-recovery actions must keep named location navigation because they
  have no shell ancestor.
- **Settings history depends on layout.** Compact pushes and wide layouts replace.
  The route-aware no-op and breakpoint-resize tests prevent duplicate stacks and
  accidental history synthesis.
- **All branch children remain laid out.** Opacity zero prevents painting and
  `TickerMode` stops animations, but the fixed stack still incurs layout cost for
  loaded branches. Keep the three-branch scope and profile before adding preload
  or substantially heavier tab roots.
- **Reduce-motion is honored for the new cross-fade only.** Route transitions are
  otherwise inconsistent app-wide (the iOS slide ignores reduce motion). This is a
  precedent, not a global fix, and is deliberately out of scope.
