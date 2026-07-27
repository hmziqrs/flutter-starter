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
  outgoing proxy and dispose its `NavigatorState`, losing scroll offsets and
  in-page widget state. (The route *stack* itself would be recovered from the
  saved `_RestorableRouteMatchList`; the live state would not.) The container
  must keep every proxy in one stable child list and animate visibility without
  removing children. Reordering is safe — proxies are keyed `ObjectKey(branch)`
  and branch navigators carry `GlobalKey`s — but this design keeps index order
  fixed; see *Cross-fade shape and paint order*.
- **`goBranch(index, {initialLocation = false})`** restores a previously visited
  branch's last stack, or goes to its root when `initialLocation: true`
  (`route.dart:1276`, impl `1522`) — exactly the reset-on-retap affordance.
- **`shell.currentIndex` is correct on cold-start deep links** (e.g.
  `/settings/appearance` resolves to index 2), and `StatefulShellRoute.builder`
  receives the `StatefulNavigationShell` as its third argument (`route.dart:1011`).
- **Branch persistence is not Flutter restoration, and it is scoped to the
  mounted shell — not the router.** `StatefulShellRoute` retains loaded branch
  navigators without a `restorationScopeId`, but
  `StatefulNavigationShellState.dispose` disposes every branch state
  (`route.dart:1538-1545`). The shell unmounts whenever the route configuration
  stops matching it, so any `go` to a top-level route resets **all** branch
  stacks: onboarding, paywall, the five auth screens, and
  `RouteErrorPage.onHome` (`app_router.dart:323`). Per-tab stacks therefore
  survive tab switches and *pushed* overlays (`/profile/edit`, `/auth/login`
  from settings) but not a full-screen flow entered with `go`. Process-death
  restoration remains deferred under the project's existing restoration policy.
- **`replace` does not preserve a page key when the target branch holds one
  page.** `NavigatingType.replace` (`parser.dart:313-326`) removes the top match
  and returns `newMatchList` verbatim if the remainder is empty, and
  `_removeRouteMatchFromList` (`match.dart:756-770`) drops the enclosing
  `ShellRouteMatch` once its submatch list empties. Declarative page keys are
  `ValueKey(matchedPath)` (`match.dart:251`, `291`), so a key survives a
  `replace` only when the matched path is unchanged. This governs the settings
  branch policy below.

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

Two structural details in that sketch are load-bearing. Branch routes keep their
existing **absolute** paths: `StatefulShellBranch` is not a `ShellRouteBase`, so
go_router's path assertion treats branch routes as top-level and requires the
leading `/`. And `goBranch(index, initialLocation: true)` resets to
`StatefulShellBranch.defaultRoute`, the first `GoRoute` in the branch — so
`settings` must stay listed before its two detail routes for reset-on-retap to
land on `/settings`.

## Cross-fading branch container

The custom container is the riskiest single piece. It lives in a new
`lib/app/shell/cross_fading_branch_container.dart` and exposes a top-level
`crossFadingBranchContainer` matching the `ShellNavigationContainerBuilder`
signature, delegating to a `_CrossFadingBranchContainer` widget.

The load-bearing invariants are:

- **Keep every branch proxy mounted in stable order.** A
  `Stack(fit: StackFit.expand)` always contains every `children[i]`; switching
  tabs never removes a proxy, and index order is held fixed so the child list is
  trivially stable. An unvisited branch is a `SizedBox.shrink()` proxy until
  go_router lazily creates its navigator (`route.dart:1656-1660`), so cold start
  lays out one branch; every loaded navigator then remains mounted.
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
  naturally retarget A→B→C without manually tracking a previous index or
  resetting an `AnimationController`: `AnimatedOpacity` rebases its tween
  `begin` to the current value and restarts. The guaranteed property is that no
  stale branch is ever *fully* revealed — not that none is visible. Mid-retarget
  the opacities no longer sum to `1` (A still falling, B reversing from a partial
  value, C rising from `0`), so three branches are briefly painted at partial
  opacity. Accepted; see *Cross-fade shape and paint order*.
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

### Cross-fade shape and paint order

Two consequences of the fixed-order `Stack` are accepted deliberately rather than
solved, and they bound what the transition can claim.

**Paint order is branch index order, not switch order.** Settings→Home paints the
*outgoing* branch on top of the incoming one; Home→Settings paints the *incoming*
on top. The transition therefore reads slightly differently by direction, which
is a weaker version of the directional cue this change removes. Making the
incoming branch always paint last would require reordering the (keyed, therefore
reorder-safe) children, at the cost of the trivially stable child list above.

**Both branches' content composites mid-fade.** Product pages here paint no
background of their own; `FScaffold` supplies the only opaque fill
(`ColoredBox`, forui `scaffold.dart`) *below* the whole stack. With complementary
opacities the composite is
`a_out·out + (1 − a_out)·a_in·in + a_in·(1 − a_in)·bg`, so both pages' cards and
text are visible at once with up to 25% scaffold bleed at the 50/50 point. This
is the opposite of the principle `CrossFadePageTransitionsBuilder` documents for
per-route transitions (`app_page_transitions.dart`): fade in over a still-opaque
outgoing page, with no see-through gap. `AppMotion.standardCurve`
(`easeOutCubic`) confines the overlap to roughly 60–70 ms of the 220 ms, which is
judged acceptable for a non-directional tab swap.

If the double exposure proves visible in review, the fix is a fade-through shape
rather than reordering: fade the outgoing branch out over the first ~35% and the
incoming branch in over the remainder, expressible as two `Interval` curves on
the same duration. That is a follow-up, not part of this change.

## Cross-tab callback audit

From a context below the stateful shell, `goNamed` or `pushNamed` to another
branch's root is the wrong abstraction: it changes a location or pushes a page
instead of selecting and restoring the target branch. In-shell tab switches must
go through `goBranch`. A router-local helper captures the reset-on-retap behavior:

```dart
void _goTab(BuildContext context, int index) {
  // Returns StatefulNavigationShellState (route.dart:1329), which owns both
  // goBranch and currentIndex.
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
| `settings.onOpenPricing` (`:255`) | `pushNamed(pricing)` | `_goTab(context, 1)` — see the Back note below |
| `settings.onOpenAppearance` (`:248`) | `pushNamed(appearance)` | `_openSettingsSection(appearance)` |
| `settings.onOpenLanguage` (`:249`) | `pushNamed(language)` | `_openSettingsSection(language)` |
| `_openSettingsSection` account/subscription/privacyAbout (`:268`) | `pushNamed(settings, ?section=)` | layout-aware `_openSettingsSection` below |
| `home`/`settings` `onOpenProfile`, `onOpenLogin` (`:55`, `:253-254`) | `pushNamed(updateProfile\|login)` | unchanged — top-level root-navigator push |
| Onboarding/paywall/auth success callbacks to Home | `goNamed(home)` | unchanged — caller is outside the shell |
| `RouteErrorPage.onHome` (`:323`) | `goNamed(home)` | unchanged — must work without a shell ancestor |

### Settings branch navigation policy

The settings branch intentionally distinguishes compact drill-in navigation from
wide pane selection. The two layouts use **different targets for the same
section**, and that asymmetry is what makes the no-transition property real:

- **Compact:** opening a section from `/settings` pushes the section's dedicated
  path (`/settings/appearance`, `/settings/language`) or `/settings?section=…`
  for the three query-only sections, so system Back returns to the overview. A
  direct cold-start `/settings/appearance` retains the current behavior: no
  synthetic overview page is inserted below it.
- **Medium and expanded:** selecting *any* of the five sections replaces to
  `/settings?section=<parameter>` — never to a dedicated `/settings/*` path. The
  matched path stays `/settings`, so the declarative page key stays
  `ValueKey('/settings')`, the page updates in place, and no route transition
  runs. Repeatedly selecting the exact current path and query is a no-op.
- **Resize:** navigation history is not synthesized or discarded merely because
  the layout changes. A section selected while wide therefore remains one page
  when resized to compact; a compact overview/detail stack remains a stack when
  resized wide.

**Why wide selection must not target `/settings/appearance`.** Page keys are
derived from the matched path, not the URI, so `/settings` and
`/settings/appearance` can never share one; and when the branch holds a single
page, `replace` discards the base match list entirely and returns a fresh
declarative match (see *Verified go_router constraints*). Replacing to a
dedicated path therefore runs the platform page transition — the Cupertino slide
on iOS, the Material zoom on Android — on every tablet-width section selection,
which is exactly the affordance this change exists to remove. It would also
rebuild `_SettingsWideLayout` from scratch, violating the rule in
`plans/initial_ui.md` that expanded navigation selects a detail pane *without
changing feature state*. Replacing to `/settings?section=…` avoids both: from a
single-page branch the degenerate path still yields page key
`ValueKey('/settings')`, and from a compact overview/detail stack the imperative
path reuses the pushed key and preserves the page beneath.

This needs no new routes — `SettingsSection.tryParse` already accepts
`appearance` and `language` (`settings_page.dart:27-36`), and `/settings` already
reads `?section=` (`app_router.dart:83`) — and no change to `SettingsPage`
callbacks. The callback context is below `AppLayoutScope`, so one helper reads
the nearest `appLayoutClassProvider`, compares the current URI with the target,
then pushes the compact target or replaces with the wide one:

```dart
void _openSettingsSection(BuildContext context, SettingsSection section) {
  // Compact drills into a dedicated path where one exists; wide always selects
  // the pane in place via ?section=, keeping the /settings page key.
  final (String name, Map<String, dynamic> queryParameters) = switch (section) {
    SettingsSection.appearance => (AppRoutes.appearanceSettings, const {}),
    SettingsSection.language => (AppRoutes.languageSettings, const {}),
    _ => (AppRoutes.settings, {'section': section.parameter}),
  };

  final layoutClass = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appLayoutClassProvider);

  if (layoutClass == AppLayoutClass.compact) {
    final target = Uri.parse(
      context.namedLocation(name, queryParameters: queryParameters),
    );
    if (GoRouterState.of(context).uri == target) return;
    unawaited(context.pushNamed<void>(name, queryParameters: queryParameters));
    return;
  }

  final wideTarget = Uri.parse(
    context.namedLocation(
      AppRoutes.settings,
      queryParameters: {'section': section.parameter},
    ),
  );
  if (GoRouterState.of(context).uri == wideTarget) return;
  context.replaceNamed(
    AppRoutes.settings,
    queryParameters: {'section': section.parameter},
  );
}
```

`ProviderScope.containerOf` passes `listen: false`: the call happens in a tap
callback, and the default would register an inherited-widget dependency outside
build.

### System Back edges that change

Two Back behaviors change and are accepted:

- **`settings.onOpenPricing` stops being reversible.** It becomes a branch
  selection, so system Back from Pricing no longer returns to
  `/settings?section=subscription`; on Android it leaves the shell. Recovery is
  by retapping the Settings tab, which restores the branch's saved stack — so
  reset-on-retap is load-bearing for recovery here, not just a convenience. The
  alternative (keeping `pushNamed`) would put a second tab's root page on the
  settings branch, which is the abstraction error this section rejects.
- **A single-page settings detail has no in-app back affordance.**
  `SettingsPage` renders none in compact detail views, so a cold-start
  `/settings/appearance` — or one left as a single page after a wide→compact
  resize — is escapable only through the tab bar. This matches today's cold-start
  behavior and is unchanged by the migration, but the resize path is new.

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
  internal. This also removes a latent coupling: both shells currently call
  `context.goNamed` directly, so the existing gallery chrome preview would throw
  if anything tapped its navigation.
- **`lib/app/shell/app_shell.dart`.** `AppShell` keeps two private fields — a
  nullable `StatefulNavigationShell? navigationShell` and a `Widget child` — with
  two constructors over them, because the preview has no shell to read. The
  default `AppShell({required StatefulNavigationShell navigationShell,
  super.key})` sets `child` to that shell, derives `selectedIndex` from
  `navigationShell.currentIndex`, and passes an `onSelectTab` closure calling
  `goBranch` with reset-on-retap. `AppShell.preview({required Widget child})`
  leaves `navigationShell` null, pins `selectedIndex` to `0` — matching the
  index that today's `location: '/home'` preview falls through to — and supplies
  a no-op tab callback. Both run the same adaptive layout dispatch.
- **`lib/app/routing/app_router.dart`.** The `ShellRoute` block becomes the
  `StatefulShellRoute` block above; the three cross-tab callbacks move to
  `_goTab`. `_settingsPage` routes all five section callbacks through the
  layout-aware `_openSettingsSection` above. Top-level routes,
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
`AppRoutes` constant, `otpLocation`, `OtpPurpose`, or navigation callback
signature changes. The shell `ValueKey`s and the `0/1/2` index contract are held
too, though those are documented under `shell-adaptive-layout` in
`architecture.md` rather than in `feature_contracts.md`. The const
`nativePageTransitionsTheme` platform map stays exactly as pinned by
`test/shared/motion/app_page_transitions_test.dart`.

Tests expected to stay green without edits include the motion-map test (per-route
and branch transitions do not touch the const map or isolated builder),
`app_router_test.dart` (all fourteen production paths and their direct-entry
history remain unchanged), `static_navigation_test.dart` (it asserts destination
state, not transitions), `motion_and_contrast_test.dart` (a gallery case, no
router), `settings_page_test.dart` (its section hops stay compact pushes, and its
one wide case is a cold-start deep link), and both integration tests, whose
`pumpAppFrames` advances 8 × 100 ms — far past a 220 ms fade, so it cannot hang
them. The golden matrix is unaffected because its harness pumps gallery fixtures
through `PreviewFrame`, never `AppShell`.

Tests that keep passing while behavior changes, and therefore need a new
assertion rather than trust:

- `settings_page_test.dart` taps `settings-view-pricing` and asserts only that
  Pricing renders. It will keep passing after that hop becomes a branch switch,
  silently losing the Back edge described above.
- `development_smoke_test.dart` navigates exclusively through
  `GoRouter.of(rootContext).go(...)`, so after this change the only place the real
  production composition runs on a device exercises no `goBranch` and no
  container code — and `just watch` shows none of it. Add one
  `tapVisible(ValueKey('compact-navigation'))` hop.

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
  settings replaces sections without duplicate history or route animation. The
  wide case must assert *no* route animation explicitly — a regression to a
  dedicated `/settings/*` target would reintroduce one silently.
- Leaving the shell with `go` (onboarding, auth, paywall, error recovery to Home)
  resets every branch stack, while a `pushNamed` overlay preserves them. Both
  halves need a test so the distinction is not mistaken for a bug later.

New coverage is required because the canonical golden harness renders gallery
pages directly rather than through `AppShell`; its existing thirteen baseline
images cannot exercise branch navigation:

1. A focused container test must inspect every `AnimatedOpacity` at the initial,
   midpoint, and settled frames. Mid-fade, outgoing and incoming branches must
   both be non-offstage and have complementary opacity; inactive branches remain
   mounted but have pointer, focus, semantics, and tickers disabled.
2. The same test must cover `disableAnimations`, verify an immediate swap, and
   retarget A→B→C before the first fade settles — asserting that the destination
   branch reaches opacity `1` and that no earlier branch is ever fully opaque,
   not that only two branches are painted.
3. A real-`App` test must push `settings → appearance`, mutate observable widget
   or scroll state, switch to Pricing, settle, switch back to Settings, and assert
   the appearance route and state survived.
4. The real-`App` test must retap the active Settings destination, assert a reset
   to `/settings`, and verify the system Back contract.
5. Router tests must cover compact push versus wide `?section=` replace (asserting
   the wide path keeps one page and runs no route animation),
   duplicate-selection no-op, direct deep-link Back behavior, top-level overlay
   placement, and pushed error-page recovery.
6. A test must pin the shell-lifetime boundary: `go` to a top-level flow and back
   resets branch stacks, while a pushed overlay preserves them.

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

A visual check with `just watch 2.5` should confirm that tab switches cross-fade
on mobile with no slide; tapping Settings after
`settings → appearance → pricing` restores Appearance; tapping Settings again
resets it to the settings root; rapid tab taps never leave a stale branch fully
opaque. Because slow motion exaggerates it, review the mid-fade double exposure
described under *Cross-fade shape and paint order* at `just watch 1` before
judging it — at 2.5× the overlap is ~170 ms rather than ~65 ms. Also check a
tablet-width window: selecting settings sections there must not slide or zoom.

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
- **Settings history depends on layout, and so does the target.** Compact pushes
  a dedicated path; wide replaces to `/settings?section=`. Retargeting the wide
  case to a `/settings/*` path is a silent regression — it reinstates the
  platform page transition and rebuilds the pane — so the no-animation assertion
  is the guard, not review. The route-aware no-op and breakpoint-resize tests
  prevent duplicate stacks and accidental history synthesis.
- **Branch stacks are shell-scoped, not session-scoped.** Any `go` to a
  full-screen flow unmounts the shell and clears every branch. This is inherent
  to `StatefulShellRoute` and out of scope to change; it only needs to be
  understood so a later report of "settings lost its stack after logging in"
  is recognized as expected.
- **Tab switching changes web history semantics.** `goBranch` into an
  already-visited branch reports with `neglect`, so it replaces the browser entry
  instead of pushing one; a first visit still pushes. Browser Back therefore
  becomes asymmetric across tabs, where today every switch is a `goNamed` that
  pushes. Accepted — web is an optional target — but it is a real change if
  `just build web` output is ever shipped.
- **All branch children remain laid out.** Opacity zero prevents painting and
  `TickerMode` stops animations, but the fixed stack still incurs layout cost for
  loaded branches. Keep the three-branch scope and profile before adding preload
  or substantially heavier tab roots.
- **Reduce-motion is honored for the new cross-fade only.** Route transitions are
  otherwise inconsistent app-wide (the iOS slide ignores reduce motion). This is a
  precedent, not a global fix, and is deliberately out of scope.
