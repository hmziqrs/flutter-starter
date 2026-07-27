# In-app search + pagination

> **Tier:** P3 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** pull-refresh

## Summary

Localized debounced search and a typed paged-list state for when content grows. Search is a
themed field plus an optional full-screen route; pagination is a hand-rolled `PagedState<T>` +
Notifier with the fetch injected as a typed port so the no-backend boundary holds. Grouped as
one spec because they share the content-scale primitives (`DataListView`, shared list bucket).

## Contract

- **Ports / value objects:**
  - **Search** — a handwritten Riverpod `debouncedQueryProvider` (~250 ms debounce). No port;
    the matcher is feature-supplied over typed `*_view_data`.
  - **Pagination** — `PagedState<T>` value object (`items` + `isLoadingNext` + `hasMore` +
    `error` + `cursor`); a `PageFetcher<T>` function type / port
    (`Future<PagedResult<T>> Function(T? cursor)`); `PagedStateNotifierBase<T>` injects the
    fetcher. Per the SettingsStore discipline, the fetcher is a typed port — never a concrete
    service in a widget.
- **Providers:** `debouncedQueryProvider` (handwritten NotifierProvider, self-contained — no
  production override; override only in tests via FakeAsync/provider override); a
  `pagedStateProvider` family keyed by fetcher.
- **Routes:** paired `AppRoutes.searchName` / `AppRoutes.searchPath` constants in
  [`lib/app/routing/app_routes.dart`](../../lib/app/routing/app_routes.dart); a **top-level**
  `GoRoute` in [`app_router.dart`](../../lib/app/routing/app_router.dart) (full-screen flows live
  top-level, not inside the `ShellRoute`). No redirect.
- **Files:**
  - add `lib/shared/widgets/search/search_field.dart` — themed `TextField` / `SearchBar`
  - add `lib/features/search/debounced_query_controller.dart` — handwritten Riverpod (feature-local, matching the `settings_controller.dart` precedent; not a new `lib/shared/search/` bucket)
  - add `lib/features/search/search_page.dart` + `lib/features/search/search_view_data.dart`
    (page + typed view-data trio)
  - add `lib/shared/state/paged_state.dart` + `lib/shared/state/paged_state_notifier.dart`
  - add `lib/shared/widgets/lists/paged_list_view.dart` — built on `DataListView` from
    [pull-refresh.md](pull-refresh.md)
  - edit `lib/app/routing/app_routes.dart` + `app_router.dart` — search route (**root composition
    edits**, checklist #4 — the only composition-root touches)
  - add `test/features/search/debounced_query_controller_test.dart` +
    `test/shared/state/paged_state_notifier_test.dart` +
    `test/shared/widgets/lists/paged_list_view_test.dart`
- **Dependencies:** none (hand-rolled). `infinite_scroll_pagination ^4.1.0` is **explicitly
  rejected** — it assumes a repository and fights the no-backend port shape.

## Backend & test surface

Backend-free. Search defaults to matching over local typed view-data (no network). Pagination's
`PageFetcher<T>` is a typed port; the default/Noop fetcher returns `common.notConnected` — no
pages are synthesized, never a faked populated next page. A real fetcher is an optional override
constructed in `AppDependencies` only when a consumer wires a source;
[`createApplication`](../../lib/bootstrap.dart) stays the injection seam.

## Tests

- **Unit/widget:** `debouncedQueryProvider` emits only after the debounce window and drops stale
  values; `PagedStateNotifier.loadNext` transitions `idle`→`loadingNext`→`appended` (or
  `error`); the Noop fetcher surfaces `notConnected`; `PagedListView` triggers `loadNext` near
  scroll end.
- **Integration:** open the search route via `createApplication` + `pumpAppFrames`; type a
  query; assert debounce + results; assert `notConnected` on a Noop-paged list.
- **Golden impact:** yes — new search route + paged-list `PreviewFrame` cases; re-baseline on
  the pinned macOS runner.
- **Dev-gallery fixture:** `PreviewFrame` search-field + paged-list (Noop fetcher →
  `notConnected`) cases, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** `search.placeholder` (field hint), `search.emptyTitle` / `search.emptyBody` (no
  results), `search.errorTitle` — synced across `en` + `ar` (RTL) + `zh-Hans`; run `just gen`.
- **RTL note:** the search-field icon/text flips under `ar`; the debounced query string itself
  is direction-neutral.

## Audit

- [x] No-backend honored as a port — **pass** (`PageFetcher<T>` port; Noop default surfaces `notConnected`, never fakes pages; search matches local data)
- [x] Feature-first ownership — **pass** (search feature under `lib/features/search/`, including the feature-local `debounced_query_controller.dart`; shared primitives under `lib/shared/{state,widgets/lists/}`)
- [ ] shared/widgets extraction ≥3 consumers — **warn** (`search_field` / `paged_list` have one concrete consumer today; clear the bar by reusing on home/settings/search, or defer)
- [x] Motion guarded — **pass** (no custom animation; route transition uses `nativePageTransitionsTheme`; scroll-triggered `loadNext` is not animation-gated)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (`search.*` added to three locales)
- [x] Strict-analysis clean — **pass** (generic `PagedState<T>`, typed `PageFetcher<T>`, no `dynamic`)
- [x] Native entitlements flagged — **n/a**
- [ ] Golden re-baseline noted on pinned macOS runner — **warn** (new search/paged matrix cases)

## Risks / notes

- **Depends on pull-refresh.** `PagedListView` builds on the `DataListView` virtualization from
  [pull-refresh.md](pull-refresh.md) — sequence after it.
- **Top-level route.** The full-screen search `GoRoute` is top-level (architecture.md routing:
  full-screen flows live outside the `ShellRoute`);
  [`EscapeDismissibleOverlay`](../../lib/shared/widgets/escape_dismissible_overlay.dart) gives
  Escape-to-dismiss.
- **Root composition edits.** New `AppRoutes` search constants + the `app_router.dart` `GoRoute`
  are the only composition-root touches ([checklist #4](../audit_checklist.md#4--composition-root-confined));
  no providers are wired outside `AppDependencies` + the `ProviderScope`.
- **Reject `infinite_scroll_pagination`.** It assumes a repository and a backend, breaking the
  no-backend port shape. The hand-rolled `PagedStateNotifier` + `PageFetcher` port preserves it.
