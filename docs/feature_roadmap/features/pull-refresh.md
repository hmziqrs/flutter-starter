# Pull-to-refresh + list virtualization

> **Tier:** P2 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** none (pairs with toast-dialogs)

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

- **Keys:** none new — reuse `common.notConnected` ([`en.i18n.json`](../../lib/i18n/en.i18n.json):20)
  for the no-backend refresh outcome.
- **RTL note:** the refresh gesture direction is platform-default; verify the indicator
  positions correctly under `ar` RTL.

## Audit

- [x] No-backend honored as a port — **n/a** (backend-free; `onRefresh` surfaces `notConnected`, never fakes success)
- [x] Feature-first ownership — **pass** (`lib/shared/widgets/refresh/` + `lib/shared/widgets/lists/`)
- [ ] shared/widgets extraction ≥3 consumers — **warn** (`home` is the only concrete consumer today; clear the bar by adopting on pricing/search lists, or document deferred consumers)
- [x] Motion guarded — **pass** (native indicator spinner; any custom spin sources durations/curves from `AppMotion` + uses `disableAnimationsOf` + a non-animated fallback that completes the refresh `Future`)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (no new keys)
- [x] Strict-analysis clean — **pass** (generic `DataListView<T>`, typed item builder, no raw types)
- [x] Native entitlements flagged — **n/a**
- [ ] Golden re-baseline noted on pinned macOS runner — **warn** (home list/grid matrix changes)

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
