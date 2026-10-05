# In-app search + pagination

> **Tier:** P3 · **Domain:** ux · **Backend:** none · **Status:** done · **Depends on:** pull-refresh

Implementation note: the search feature (field, debounce, page, top-level route), the
`PagedState<T>`/`PagedStateNotifierBase` port shape with an honest Noop fetcher, tests, i18n,
and gallery fixtures are done and verified. Checklist item 3 is closed via the
[C1](../contracts.md#c1--scope-is-comprehensive) designation recorded below (`SearchField` and
`PagedListView` keep their one production consumer — the search page — plus gallery fixtures).
The corpus fetch loads through the offline-aware cache primitive (see *Backend & test surface*)
and the promised integration coverage exists (`integration_test/search_flow_test.dart`).

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
  - add `lib/shared/widgets/lists/paged_list_view.dart` — sibling of `DataListView` from
    [pull-refresh.md](pull-refresh.md) in the shared lists bucket; renders via `ListView.builder`
    directly (`paged_list_view.dart:73`), not on top of `DataListView`
  - edit `lib/app/routing/app_routes.dart` + `app_router.dart` — search route (**root composition
    edits**, checklist #4 — the only composition-root touches)
  - add `test/features/search/debounced_query_controller_test.dart` +
    `test/shared/state/paged_state_notifier_test.dart` +
    `test/shared/widgets/lists/paged_list_view_test.dart`
- **Dependencies:** none (hand-rolled). `infinite_scroll_pagination ^4.1.0` is **explicitly
  rejected** — it assumes a repository and fights the no-backend port shape.

## Backend & test surface

Backend-free by default. Search matches over a corpus that loads through the offline-aware cache
primitive ([offline-cache](offline-cache.md)): `searchCorpusSourceProvider`
(`lib/features/search/search_corpus.dart`) is the typed seam for the shared `HttpCacheDataSource`
(`GET /v1/cache/search-corpus`); its default `null` keeps search on the bundled local corpus (no
network), exactly as before. When a source is wired at the composition root,
`buildCachedFutureProvider` serves the corpus (fresh → stale-offline → conditional etag fetch)
with the bundled corpus as the honest fallback — never a synthesized list. Pagination's
`PageFetcher<T>` is a typed port; the default/Noop fetcher returns `common.notConnected` — no
pages are synthesized, never a faked populated next page. A real fetcher is an optional override
constructed in `AppDependencies` only when a consumer wires a source;
[`createApplication`](../../lib/bootstrap.dart) stays the injection seam.

## Tests

- **Unit/widget:** `debouncedQueryProvider` emits only after the debounce window and drops stale
  values; `PagedStateNotifier.loadNext` transitions `idle`→`loadingNext`→`appended` (or
  `error`); the Noop fetcher surfaces `notConnected`; `PagedListView` triggers `loadNext` near
  scroll end.
- **Corpus/cache unit:** `test/features/search/search_corpus_test.dart` pins the degradation
  ladder — no source wired → bundled fixtures; online source → fetched corpus cached with its
  etag; unknown cache key → honest fallback to the bundled corpus.
- **Integration:** `integration_test/search_flow_test.dart` opens the search route via
  `createApplication` + `pumpAppFrames`; types a query; asserts debounce + filtered results +
  the empty state-view; then asserts `notConnected` on the Noop-paged gallery case.
- **Golden impact:** none committed today — no search/paged case exists in
  `test/goldens/baselines/` (listing the directory matches neither `search` nor `paged`).
  Committed coverage is the dev-gallery `PreviewFrame` fixtures; adding canonical matrix
  baselines is deferred to the pinned macOS 26 CI re-baseline (tracked repo-wide).
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
- [x] shared/widgets extraction ≥3 consumers — **pass (designated)**: `SearchField` and `PagedListView` each have exactly one production consumer (`search_page.dart`) plus their gallery fixtures; the widget bar is met via the [C1](../contracts.md#c1--scope-is-comprehensive) deferred-consumer designation recorded in this doc — `SearchField`: settings (filter preference rows), license-share-update (filter the OSS registry), push-notifications (filter delivered messages); `PagedListView`: license-share-update (paged registry), announcements (paged history), push-notifications (paged message list). Re-audit as those land; demote to feature-local if they never materialize. The pure-Dart `PagedStateNotifierBase` keeps its ≥1-consumer bar (`SearchResultsController` in `search_page.dart`) plus documented reuse intent.
- [x] Composition root confined — **pass**: the only root touches are `AppRoutes.search`/`searchPath` (`app_routes.dart:60-61`) and the top-level `...buildSearchRoutes()` composition (`app_router.dart:43`, outside the `StatefulShellRoute`); `debouncedQueryProvider` is self-contained with no production override; `searchCorpusSourceProvider` is a feature-local seam defaulting to `null` — the concrete `HttpCacheDataSource` is only ever constructed outside feature code (composition root or tests); `search_page.dart` imports no `go_router` (navigation arrives as the `onBack` callback, translated in `search_routes.dart`).
- [x] Motion guarded — **pass**: no custom animation; the route uses the shared native page-transitions theme and `loadNext` is scroll-triggered (`paged_list_view.dart:110-122`), not animation-gated; feature tests never use `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: `search.title/placeholder/emptyTitle/emptyBody/errorTitle` present in all three locales (verified in `lib/i18n/{en,ar,zh-Hans}.i18n.json`); RTL back-chevron flips explicitly (`search_page.dart:200-204`).
- [x] Strict analysis clean — **pass**: generic `PagedState<T>`/`PagedResult<T>` (Freezed, committed generated output), typed `PageFetcher<T>` typedef, sealed status enum; no `dynamic`.
- [x] Generated code untouched — **pass**: `paged_state.freezed.dart` + `search_view_data.freezed.dart` are committed builder output; working-tree generated-file changes trace to source edits via `just gen`.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass (fixtures; matrix deferred)**: committed `PreviewFrame` cases `searchPagination.field`, `searchPagination.paged`, and `searchPagination.pagedNoBackend` (Noop fetcher → `notConnected`) in `search_pagination_gallery_cases.dart`, registered in `gallery_registry.dart:50`. No canonical golden-matrix baselines exist for search/paged yet — deferred to the pinned macOS 26 CI re-baseline (tracked repo-wide; that re-baseline is outstanding because the committed baselines are already outdated vs HEAD — 13/14 canonical comparisons fail locally).
- [x] Port-reuse consistency — **pass**: no parallel to existing port families; pagination has exactly one seam (`PageFetcher<T>`), and the search matcher stays feature-owned rather than inventing a shared search port.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the Noop fetcher surfaces `notConnected` (tested), `PagedListView` offers retry rather than showing stale items as fresh, and empty results render `search.emptyTitle` instead of fabricated matches.

## Risks / notes

- **Sibling of pull-refresh's `DataListView`, not built on it.** `PagedListView` renders via
  `ListView.builder` directly (`paged_list_view.dart:73`) — same shared lists bucket, but there
  is no `DataListView` dependency to sequence after.
- **Top-level route.** The full-screen search `GoRoute` is top-level (architecture.md routing:
  full-screen flows live outside the `ShellRoute`);
  [`EscapeDismissibleOverlay`](../../lib/shared/widgets/escape_dismissible_overlay.dart) gives
  Escape-to-dismiss.
- **Root composition edits.** New `AppRoutes` search constants + the `app_router.dart` `GoRoute`
  are the only composition-root touches ([checklist #4](../contracts.md#4--composition-root-confined));
  no providers are wired outside `AppDependencies` + the `ProviderScope`.
- **Reject `infinite_scroll_pagination`.** It assumes a repository and a backend, breaking the
  no-backend port shape. The hand-rolled `PagedStateNotifier` + `PageFetcher` port preserves it.
