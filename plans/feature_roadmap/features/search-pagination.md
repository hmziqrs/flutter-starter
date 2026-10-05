# In-app search + pagination

> **Tier:** P3 · **Domain:** ux · **Backend:** none · **Status:** in-progress · **Depends on:** pull-refresh

Implementation note: the search feature (field, debounce, page, top-level route), the
`PagedState<T>`/`PagedStateNotifierBase` port shape with an honest Noop fetcher, tests, i18n,
and gallery fixtures are done and verified. The feature stays `in-progress` solely on
checklist item 3 — `SearchField` and `PagedListView` each have one production consumer (the
search page) plus the gallery, and this doc does not designate ≥3 deferred consumers. Reuse
on further real lists or record the designation to close it.

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

- [x] No-backend honored as a port — **pass**: typed `PageFetcher<T>` port (`paged_state.dart:35`); `noopPageFetcher` throws `PagedFetchException.notConnected()` on every call (`paged_state_notifier.dart:51-53`) and `paged_state_notifier_test.dart:152-168` pins that behavior; `PagedListView` renders the error state-view with `common.notConnected` + retry (`paged_list_view.dart:58-67`); search itself matches local typed view-data — never a faked populated page.
- [x] Feature-first ownership — **pass**: `lib/features/search/{search_page,search_routes,search_view_data,debounced_query_controller}.dart` (feature-local controller per the settings precedent); shared primitives under `lib/shared/state/` + `lib/shared/widgets/{search,lists}/`.
- [ ] shared/widgets extraction ≥3 consumers — **warn**: `SearchField` and `PagedListView` each have exactly one production consumer (`search_page.dart:14-15`) plus their gallery fixtures; the pure-Dart `PagedStateNotifierBase` meets its lower bar (≥1 consumer — `SearchResultsController` in `search_page.dart:28` — plus documented reuse intent), but the widget bar (≥3 concrete or designated) is unmet by this doc.
- [x] Composition root confined — **pass**: the only root touches are `AppRoutes.search`/`searchPath` (`app_routes.dart:60-61`) and the top-level `...buildSearchRoutes()` composition (`app_router.dart:43`, outside the `StatefulShellRoute`); `debouncedQueryProvider` is self-contained with no production override; `search_page.dart` imports no `go_router` (navigation arrives as the `onBack` callback, translated in `search_routes.dart`).
- [x] Motion guarded — **pass**: no custom animation; the route uses the shared native page-transitions theme and `loadNext` is scroll-triggered (`paged_list_view.dart:110-122`), not animation-gated; feature tests never use `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: `search.title/placeholder/emptyTitle/emptyBody/errorTitle` present in all three locales (verified in `lib/i18n/{en,ar,zh-Hans}.i18n.json`); RTL back-chevron flips explicitly (`search_page.dart:200-204`).
- [x] Strict analysis clean — **pass**: generic `PagedState<T>`/`PagedResult<T>` (Freezed, committed generated output), typed `PageFetcher<T>` typedef, sealed status enum; no `dynamic`.
- [x] Generated code untouched — **pass**: `paged_state.freezed.dart` + `search_view_data.freezed.dart` are committed builder output; working-tree generated-file changes trace to source edits via `just gen`.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: committed `PreviewFrame` cases `searchPagination.field`, `searchPagination.paged`, and `searchPagination.pagedNoBackend` (Noop fetcher → `notConnected`) in `search_pagination_gallery_cases.dart`, registered in `gallery_registry.dart:50` — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (currently pending).
- [x] Port-reuse consistency — **pass**: no parallel to existing port families; pagination has exactly one seam (`PageFetcher<T>`), and the search matcher stays feature-owned rather than inventing a shared search port.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the Noop fetcher surfaces `notConnected` (tested), `PagedListView` offers retry rather than showing stale items as fresh, and empty results render `search.emptyTitle` instead of fabricated matches.

## Risks / notes

- **Depends on pull-refresh.** `PagedListView` builds on the `DataListView` virtualization from
  [pull-refresh.md](pull-refresh.md) — sequence after it.
- **Top-level route.** The full-screen search `GoRoute` is top-level (architecture.md routing:
  full-screen flows live outside the `ShellRoute`);
  [`EscapeDismissibleOverlay`](../../lib/shared/widgets/escape_dismissible_overlay.dart) gives
  Escape-to-dismiss.
- **Root composition edits.** New `AppRoutes` search constants + the `app_router.dart` `GoRoute`
  are the only composition-root touches ([checklist #4](../contracts.md#4--composition-root-confined));
  no providers are wired outside `AppDependencies` + the `ProviderScope`.
- **Reject `infinite_scroll_pagination`.** It assumes a repository and a backend, breaking the
  no-backend port shape. The hand-rolled `PagedStateNotifier` + `PageFetcher` port preserves it.
