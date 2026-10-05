# Offline-first caching layer

> **Tier:** P3 · **Domain:** infra · **Backend:** test-server · **Status:** done · **Depends on:** connectivity
>
> Implementation audit (2026-10-04, updated 2026-10-05): port + file-backed production store +
  connectivity-gated read primitive with conditional-get (etag/`If-None-Match`/304
  fresh-extend) + `HttpCacheDataSource` + unit tests + diagnostics + live-server e2e verified.
  The primitive has its first production consumer: search's corpus fetch
  (`lib/features/search/search_corpus.dart:24,39`).

## Summary

A port-based cache (read/write/invalidate by key with TTL) plus a connectivity sensor so the app
can serve last-seen content when offline and refresh when online — the backbone of resilient
read paths. The cache store itself is local and works fully offline; the "backend" is whatever
remote data source a feature uses to populate it, exercised against the test server.

## Contract

- **Ports / value objects:** `CacheStore` abstract interface mirroring
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) **exactly** —
  `readJson(key) -> Future<CacheEntry?>`, `writeJson(key, entry)`, `remove(key)`, plus an `age(key)`
  accessor; **no** `clearAll` (per-key discipline only, exceptions wrapped in a
  `CacheStoreException`). Typed `CacheEntry<T>` (`value T`, `fetchedAt` epoch, `ttlSeconds`,
  `etag?`, `value-equality`); `CacheStatus` (`fresh | stale | absent`). `SharedPreferences` is
  per-key small-string only and **unsuitable** for payload blobs — the production store is
  file-backed. This feature also depends on the **shared**
  [`ConnectivityService`](connectivity.md) port per
  [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends) (built once under
  `lib/infrastructure/connectivity/` by [`connectivity`](connectivity.md); offline-cache is a
  reader, not a second port).
- **Providers:** handwritten Riverpod — `cacheStoreProvider` (overridden at the
  [`ProviderScope`](../../../lib/app/app.dart)) and a `cachedFutureProvider<T>(key, fetch)`
  family that serves fresh→stale→fetch with connectivity gating. **Reuse the
  `connectivityStatusProvider` already owned by [`connectivity`](connectivity.md)** — do **not**
  redeclare it here or introduce a second connectivity sensor (port-reuse,
  [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)). Follow the
  [`SettingsController`](../../../lib/features/settings/settings_controller.dart) shape; **no**
  codegen.
- **Routes:** none — this is an infra primitive, not a surface.
- **Files:** feature-first + infra ownership (the port lives in `lib/infrastructure/` like the
  sole production `SharedPreferencesSettingsStore`, because it is a cross-cutting adapter, not a
  product feature):
  - `lib/infrastructure/cache/cache_store.dart` (port)
  - `lib/infrastructure/cache/cache_entry.dart`
  - `lib/infrastructure/cache/cache_store_exception.dart`
  - `lib/infrastructure/cache/in_memory_cache_store.dart` (test/hermetic default)
  - `lib/infrastructure/cache/file_cache_store.dart` (production default, file-backed)
  - `lib/infrastructure/cache/cached_future_provider.dart` (the offline-aware read primitive;
    watches the existing `connectivityStatusProvider` from [`connectivity`](connectivity.md),
    never defines its own — kept here with the port; consumed by search's corpus fetch
    (`lib/features/search/search_corpus.dart:24,39`))
  - `lib/infrastructure/cache/http_cache_data_source.dart` (the reference HTTP data source:
    conditional `GET /v1/cache/{key}`, parses `{data, etag, ttlSeconds, epoch}`, and wires a
    `CachedFutureSpec` via `spec()` so the primitive is drivable against a real socket)
  - `test/infrastructure/cache/in_memory_cache_store_test.dart`
  - `test/infrastructure/cache/file_cache_store_test.dart`
  - `test/infrastructure/cache/cached_future_provider_test.dart`
  - `test/infrastructure/cache/http_cache_data_source_test.dart`
  - `test/e2e/cache_e2e_test.dart` (live-server e2e: 200 refresh + etag store, 304
    short-circuit, offline stale-serve)
  - **shared port touchpoint (flagged):** `lib/infrastructure/connectivity/connectivity_service.dart`
    + `connectivity_plus_service.dart` are owned by [`connectivity`](connectivity.md). If that
    feature has not landed, introduce the port there as part of this work — build **one**
    `ConnectivityService`, used by both the banner and the cache.
  - **root-composition edits (flagged):** [`lib/app/dependencies.dart`](../../../lib/app/dependencies.dart)
    (`AppDependencies.production` wires `FileCacheStore` + the connectivity impl),
    [`lib/app/app.dart`](../../../lib/app/app.dart) (`ProviderScope` overrides).
- **Dependencies:** `connectivity_plus` (owned by [`connectivity`](connectivity.md)),
  `path_provider` (for `FileCacheStore` directory resolution). `sqflite`/`drift`/`hive` are
  **not** added — a file-per-key store is sufficient for a starter and avoids a new storage
  subsystem; escalate before introducing one.

## Backend & test surface

Per [C2](../contracts.md#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
the starter runs green with **zero backend**. Here the local store *is* real (it is not a Noop),
and "no backend" means no remote data source is wired — features that try to refresh see
`common.notConnected`.

- **Local production default (real, not Noop)** — `FileCacheStore` resolves a directory via
  `path_provider` and writes one file per key with the serialized `CacheEntry`. It works fully
  offline; constructed in `AppDependencies.production`. `InMemoryCacheStore` is the hermetic
  default for tests and for `PreviewFrame`/dev-gallery isolation.
- **The "backend" is feature-specific.** offline-cache does not own a remote source; it provides
  the cache primitive + the connectivity-gated `cachedFutureProvider`. A feature supplies its own
  typed `fetch: Future<T> Function()`; without a real network source that fetch surfaces
  `common.notConnected` and the cache serves stale (or `absent`). Never fake a populated cache
  for a source that does not exist.
- **Test-server contract** — [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server)
  implements a generic cacheable data-source route group so the offline-aware read primitive is
  exercised against real network paths:
  - `GET /v1/cache/{key}` -> `200 {data, etag, ttlSeconds, epoch}` or `304` (when `If-None-Match`
    matches) or `404`
  - `GET /v1/cache/{key}?minEpoch=<ts>` -> `200` only if newer, else `304`
  Integration tests start the server on a random port, prime the cache, toggle
  `ConnectivityService` offline (via a `StreamController` fake), and assert the stale entry is
  served; toggle back online and assert the refresh runs.
- **Fakes** — `InMemoryCacheStore` (controllable entries + `failReads`/`failWrites` toggles,
  mirroring [`InMemorySettingsStore`](../../../lib/features/settings/in_memory_settings_store.dart))
  + a `StreamController`-backed `ConnectivityService` fake. No Mocktail.

## Tests

- **Unit/widget:** `in_memory_cache_store_test.dart` + `file_cache_store_test.dart` — per-key
  read/write/remove round-trips, `age`/TTL expiry (`fresh`→`stale`), `CacheStoreException`
  wrapping on I/O failure, **no** `clearAll` on the interface. `cached_future_provider` test:
  serves fresh without fetch, serves stale then refreshes when online, surfaces `notConnected`
  when offline **and** absent.
- **Integration:** `test/e2e/cache_e2e_test.dart` drives `HttpCacheDataSource` +
  `buildCachedFutureProvider` against the live `tools/hono_server` from a headless
  `ProviderContainer` (overriding `cacheStoreProvider` + `connectivityServiceProvider` with
  fakes, settled by a bounded 8-turn microtask loop — no widgets, no `pumpAndSettle`). Asserts
  online refresh (etag + server TTL stored) + the `If-None-Match` `304` short-circuit + offline
  stale-serve with no request leaving the client.
- **Golden impact:** none directly — the cache is infra. A consuming feature that renders a
  stale banner ("showing saved content") adds its own `PreviewFrame` case; this feature owns no
  visual state.
- **Dev-gallery fixture:** none — no UI surface. A Diagnostics trigger (under
  `developmentToolsEnabled`) to dump cache key sizes/ages is optional and lives on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart).

## i18n

- **Keys:** none of its own (infra). A consuming feature that surfaces a "stale content" affordance
  owns its own key (e.g. `common.showingSavedContent`), added in sync across `en` + `ar` +
  `zh-Hans`.
- **RTL note:** n/a (no UI surface).

## Audit

- [x] **No-backend honored as a port** — **pass**: port + real local default + live network
  path verified: `CacheStore` (`lib/infrastructure/cache/cache_store.dart:4` — per-key
  `read/write/remove/age`, no `clearAll`), `FileCacheStore` production default
  (`lib/app/dependencies.dart:315-330`), `GET /v1/cache/:key` with ETag/`minEpoch` 304s
  (`tools/hono_server/src/index.ts`), exercised from Dart by `HttpCacheDataSource` +
  the conditional-get semantics in `cachedFutureProvider`, covered by the unit tests and
  `test/e2e/cache_e2e_test.dart` (live server). Resolves the prior warn.
- [x] **Feature-first ownership; no core/ utils/ buckets** — **pass**: the port and the
  offline-aware read primitive live in `lib/infrastructure/cache/` (cross-cutting adapter,
  peer of `SharedPreferencesSettingsStore`); no buckets.
- [x] **Shared extraction >=3 consumers** — **pass** (updated 2026-10-05): nothing was
  extracted to `lib/shared/`; the `cachedFutureProvider` primitive stays under
  `lib/infrastructure/cache/` and now has a production consumer — search's corpus fetch wires
  it via `searchCorpusSourceProvider` → `buildCachedFutureProvider`
  (`lib/features/search/search_corpus.dart:24,39`, pinned by
  `test/features/search/search_corpus_test.dart`), so the >=1-consumer bar for shared state
  helpers is met outright. Resolves the pre-written warn.
- [x] **Composition root confined** — **pass**: `FileCacheStore` wired only in
  `lib/app/dependencies.dart:315-330`; `cacheStoreProvider` overridden in
  `lib/app/app.dart:147`; `connectivityStatusProvider` is read, never redeclared
  (`cached_future_provider.dart:115`).
- [x] **Motion guarded** — **n/a**: no animations.
- [x] **i18n synced en/ar/zh-Hans** — **n/a**: no keys of its own; `gen-check` unaffected.
- [x] **Strict analysis clean** — **pass**: typed `CacheEntry<T>` + `CacheCodec<T>` generics,
  exhaustive `CacheStatus` handling, `CacheUnavailable` exception type; no `dynamic` in the
  area (grep clean).
- [x] **Generated code untouched** — **n/a**: no codegen output in this feature.
- [x] **Native entitlements flagged** — **pass**:
  `FileCacheStore.resolveApplicationSupportDirectory()` uses `path_provider`
  (`file_cache_store.dart:16-17`); the macOS app-sandbox container's Application Support
  directory is writable with the committed entitlements
  (`macos/Runner/DebugProfile.entitlements` enables only app-sandbox + JIT/network), and the
  macOS build runs in CI (`.github/workflows/release.yml`). Resolves the pre-written warn.
- [x] **Goldens re-baselined + dev-gallery fixture** — **n/a**: no UI; the optional cache
  diagnostics rows live on the dev-only `DiagnosticsPage`
  (`diagnostics_page.dart:33-35, 169`).
- [x] **Port-reuse consistency** — **pass**: reads the existing `connectivityStatusProvider`
  owned by `connectivity` (`cached_future_provider.dart:115`); `ConnectivityPlusService` is
  constructed only in `dependencies.dart:405`; never a second sensor.
- [x] **Config rule respected** — **pass**: web vs file selection is by `kIsWeb`, not
  config; no runtime env switching.
- [x] **Honest feedback / no faked success** — **pass**: offline + absent throws
  `CacheUnavailable` (`cached_future_provider.dart:118-122`, the `*Unavailable` pattern)
  instead of faking data; stale entries are labeled `CacheStatus.stale` for the consumer;
  covered by `test/infrastructure/cache/cached_future_provider_test.dart`.

## Risks / notes

- **This feature escalates the no-backend boundary.** Per the source research, there is
  **deliberately no network/db/file-storage adapter today** (architecture.md: only
  `log_redactor` has tests; no network adapter exists by design). `FileCacheStore` is the first
  non-`SharedPreferences` persistence adapter — confirm with the architecture owner that a second
  storage port is sanctioned before building, since it sets the precedent for future file/db
  adapters. If declined, fall back to a `SharedPreferences`-backed JSON store with a documented
  payload-size cap.
- **Port reuse is mandatory.** The connectivity sensor is **shared** with
  [`connectivity`](connectivity.md) ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)).
  Never instantiate `connectivity_plus` directly in the cache or in a widget — read
  `connectivityStatusProvider`, which reads the one `ConnectivityService` port. If
  [`connectivity`](connectivity.md) has not shipped, land the port here and have the banner adopt
  it — but sequence [`connectivity`](connectivity.md) **first** to avoid rework.
- **Stale-serve contract, not silent failure.** When offline, `cachedFutureProvider` must serve
  the stale entry **and** signal staleness to the consumer (return a `CacheStatus.stale` or a
  typed wrapper) so the UI can show "saved content" honestly — it must not return fresh-looking
  data that is actually days old. This is the honest-feedback rule applied to data, not actions.
- **TTL + `etag` discipline.** Cache freshness is `fetchedAt + ttlSeconds` vs now; the test
  server honors `If-None-Match`/`304` so the network path is realistic, not a mock. Never
  short-circuit the refresh by treating any cached hit as fresh.
- **No `clearAll`.** Per-key `remove` only, mirroring `SettingsStore`; a "clear cache" affordance
  (if ever added) iterates known keys, not a bulk wipe — do not widen the port interface.
- **Sequencing.** P3 — the last infra piece; depends on [`connectivity`](connectivity.md)
  (shared port). Its first real data-source consumer has landed: search's corpus fetch goes
  through `cachedFutureProvider` ([`search-pagination`](search-pagination.md) —
  `search_corpus.dart:24,39`), while pagination itself keeps its own `PageFetcher<T>` +
  `PagedState<T>` (paged fetching is a different shape than single-value caching, by design).
  No UI/golden impact of its own.
