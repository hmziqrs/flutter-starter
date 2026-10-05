# Pull-to-refresh + list virtualization

> **Tier:** P2 · **Domain:** ux · **Backend:** none · **Status:** in-progress · **Depends on:** none (pairs with toast-dialogs)

Implementation note: all four widgets, the home migration, tests, and gallery fixtures are
done and verified (including the `PlatformCapabilities.isApplePlatform` addition this doc
recommended). Home's scroll frame now also wires a real `onRefresh` through
`AppRefreshIndicator` — the backend-free outcome surfaces `common.notConnected` via `AppToast`
and the indicator dismisses (asserted in `integration_test/home_lists_test.dart`). The feature
stays `in-progress` solely on checklist item 3 — `home_page` is the only production consumer
(`DataListView` + `AppRefreshIndicator`); `RefreshableListView` and `ResponsiveListGrid` are
gallery-only, and this doc does not designate ≥3 deferred consumers. Adopt on further real
lists (pricing/search/settings) or record the designation to close it.

## Summary

Standard swipe-to-refresh and lazily-building lists. ForUI 0.24.1 ships neither, and
[`home_page.dart`](../../lib/features/home/home_page.dart) uses a static `ListView` (O(n)
children at line 39). This wraps Flutter's `RefreshIndicator` with the app accent and provides a
`DataListView<T>` that bakes in the repo's padding and responsive-grid conventions.

## Contract

- **Ports / value objects:** No port — backend-free. Refresh takes a typed
  `onRefresh: Future<void> Function()`. `DataListView<T>` takes a typed item builder +
  `ValueKey`-per-item; `ResponsiveListGrid` takes cross-axis counts keyed on `AppLayoutScope`.
- **Providers:** none.
- **Routes:** none.
- **Files:**
  - add `lib/shared/widgets/refresh/app_refresh_indicator.dart` — `RefreshIndicator` themed via
    [`ForuiThemeFactory._accentColors`](../../lib/shared/theme/forui_theme_factory.dart);
    Cupertino style on Apple platforms
  - add `lib/shared/widgets/refresh/refreshable_list_view.dart` — `RefreshIndicator` +
    `ListView.builder` composition
  - add `lib/shared/widgets/lists/data_list_view.dart` — lazy builder with
    [`AppSpacing`](../../lib/shared/theme/app_spacing.dart) / [`AppSizes`](../../lib/shared/theme/app_sizes.dart)
    padding and `ValueKey` semantics
  - add `lib/shared/widgets/lists/responsive_list_grid.dart` — `AppLayoutScope`-driven
    cross-axis counts (generalizes home's 1/2/3-column switch)
  - edit [`lib/features/home/home_page.dart`](../../lib/features/home/home_page.dart) — migrate
    the static `ListView` at line 39 to the lazy builder
  - add `test/shared/widgets/refresh/app_refresh_indicator_test.dart` +
    `test/shared/widgets/lists/data_list_view_test.dart`
  - add refresh/grid `PreviewFrame` cases to the dev gallery
- **Dependencies:** none (Flutter SDK `RefreshIndicator` + `ListView.builder`).

## Backend & test surface

Backend-free. The default impl is real and local — `onRefresh` is feature-supplied; a feature
with no backend surfaces `common.notConnected` via the toast system
([toast-dialogs.md](toast-dialogs.md)) rather than faking a successful refresh. No data is
synthesized.

## Tests

- **Unit/widget:** `AppRefreshIndicator` applies the accent color; `RefreshableListView` calls
  `onRefresh` and dismisses on `Future` completion; `DataListView` virtualizes (only the visible
  items build) and assigns stable `ValueKey`s; the responsive grid cross-axis switches on
  `AppLayoutScope` width.
- **Integration:** `home` refresh gesture via `createApplication` + `pumpAppFrames`; assert the
  `notConnected` toast surfaces (no backend) and the indicator dismisses.
- **Golden impact:** yes — the home grid/list matrix changes (static→builder, accent
  indicator); re-baseline on the pinned macOS runner.
- **Dev-gallery fixture:** `PreviewFrame` refreshable-list + responsive-grid cases, gated
  behind `developmentToolsEnabled`.

## i18n

- **Keys:** none new — reuse `common.notConnected` ([`en.i18n.json`](../../lib/i18n/en.i18n.json):21)
  for the no-backend refresh outcome.
- **RTL note:** the refresh gesture direction is platform-default; verify the indicator
  positions correctly under `ar` RTL.

## Audit

- [x] No-backend honored as a port — **n/a**: backend-free; `onRefresh` is feature-supplied and a no-backend refresh surfaces `notConnected` (e.g. via `AppToast` in the connectivity/announcements banners), never a faked successful refresh; no plugin calls in the widgets.
- [x] Feature-first ownership — **pass**: `lib/shared/widgets/refresh/{app_refresh_indicator,refreshable_list_view}.dart` + `lib/shared/widgets/lists/{data_list_view,responsive_list_grid}.dart`; no `core/`/`utils/` buckets.
- [ ] shared/widgets extraction ≥3 consumers — **warn**: concrete consumers today are `home_page.dart` (`DataListView` for the activity tiles plus `AppRefreshIndicator` wrapping the home scroll frame with a real `onRefresh`) and the dev gallery (`pull_refresh_gallery_cases.dart` imports `RefreshableListView` + `ResponsiveListGrid`); search landed its own `PagedListView` without adopting `DataListView` — 2 distinct consumers, no ≥3 designation, so the bar is unmet.
- [x] Composition root confined — **pass**: no providers or adapters; pure widgets, nothing to wire in `AppDependencies`/`ProviderScope`.
- [x] Motion guarded — **pass**: `app_refresh_indicator.dart:47` reads `MediaQuery.disableAnimationsOf` and renders the spinner transparent under reduce-motion while the `onRefresh` `Future` still completes (`app_refresh_indicator_test.dart:45`); `refreshable_list_view.dart:49-50` falls back from Cupertino to the Material indicator under reduce-motion; native indicator animation otherwise; feature tests never use `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: no new keys; reuses `common.loading` / `common.notConnected` (`app_refresh_indicator.dart:48`); RTL exercised in `app_refresh_indicator_test.dart:60`.
- [x] Strict analysis clean — **pass**: generic `DataListView<T>` / `RefreshableListView<T>` / `ResponsiveListGrid<T>` with typed item builders and `String Function(T)` keyOf, exhaustive `AppLayoutClass` switch (`responsive_list_grid.dart:21-26`); no raw types.
- [x] Generated code untouched — **pass**: no codegen for this feature; working-tree generated-file changes trace to source edits via `just gen`.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: committed `PreviewFrame` cases `pullRefresh.list` / `pullRefresh.grid` (`pull_refresh_gallery_cases.dart`, registered in `gallery_registry.dart:34`); home list/grid matrix change documented above — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (currently pending).
- [x] Port-reuse consistency — **pass**: no new port; the Cupertino/Material branch reads the shared `PlatformCapabilities` seam (`isApplePlatform`, added at `platform_capabilities.dart:37`) instead of scattering `Platform.is*` checks, exactly as this doc's risk note prescribed.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the indicator dismisses when the `onRefresh` `Future` completes (`app_refresh_indicator.dart:32-42`); no data is synthesized and success is never implied without the feature's own result.

## Risks / notes

- **`PlatformCapabilities` has no `isApplePlatform`.**
  [`lib/infrastructure/platform/platform_capabilities.dart`](../../lib/infrastructure/platform/platform_capabilities.dart)
  exposes only `platform` (a `String` from `defaultTargetPlatform.name`), `isWeb`, and
  `supportsFileSystem`. To pick Cupertino vs Material refresh, either add a derived
  `isApplePlatform` getter (read-only, no channels — matches the existing pattern) or branch on
  `defaultTargetPlatform` inside the wrapper. Prefer extending `PlatformCapabilities` so the
  platform seam stays in one place.
- **Pairs with toast-dialogs.** The no-backend refresh outcome needs the toast wrapper
  ([toast-dialogs.md](toast-dialogs.md)) to surface `notConnected` consistently.
- **Generalize home's grid switch.** `DataListView` / `ResponsiveListGrid` must lift the 1/2/3
  `AppLayoutScope` column switch out of `home_page.dart` rather than duplicate it.
