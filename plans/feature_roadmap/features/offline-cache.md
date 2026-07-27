# Offline-first caching layer

> **Tier:** P3 · **Domain:** infra · **Backend:** test-server · **Status:** planned · **Depends on:** connectivity

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
  [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends) (built once under
  `lib/infrastructure/connectivity/` by [`connectivity`](connectivity.md); offline-cache is a
  reader, not a second port).
- **Providers:** handwritten Riverpod — `cacheStoreProvider` (overridden at the
  [`ProviderScope`](../../../lib/app/app.dart)) and a `cachedFutureProvider<T>(key, fetch)`
  family that serves fresh→stale→fetch with connectivity gating. **Reuse the
  `connectivityStatusProvider` already owned by [`connectivity`](connectivity.md)** — do **not**
  redeclare it here or introduce a second connectivity sensor (port-reuse,
  [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)). Follow the
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
    never defines its own — kept here with the port until a consumer lands; no designated
    consumer today)
  - `test/infrastructure/cache/in_memory_cache_store_test.dart`
  - `test/infrastructure/cache/file_cache_store_test.dart`
  - `test/infrastructure/cache/cached_future_provider_test.dart`
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

Per [D2](../decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
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
- **Test-server contract** — [`tools/test_server/`](../decisions.md#d3--minimal-in-repo-test-server-tools-test_server)
  implements a generic cacheable data-source route group so the offline-aware read primitive is
  exercised against real network paths:
  - `GET /v1/cache/{key}` -> `200 {data, etag, ttlSeconds}` or `304` (when `If-None-Match` matches)
    or `404`
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
- **Integration:** reuse `createApplication`; drive the cache against `tools/test_server` with
  `pumpAppFrames` (8 bounded frames), **never** `pumpAndSettle`. Assert offline stale-serve +
  online refresh + `etag`-based `304` short-circuit.
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

- [x] **pass** — No-backend honored: `FileCacheStore` is a real local store; features without a
  remote source surface `notConnected`, never fake a populated cache.
- [x] **pass** — Ownership: the **port** and the offline-aware read primitive both live in
  `lib/infrastructure/cache/` (cross-cutting adapter, peer of
  `SharedPreferencesSettingsStore`); no `lib/shared/state/` primitive is committed until a
  consumer lands. No `core/`/`utils/` bucket.
- [ ] **warn** — Shared extraction: `lib/shared/state/` primitives need ≥1 consumer + reuse
  intent per checklist #3; no designated consumer today (the primitive is held under
  `lib/infrastructure/cache/` until one lands).
- [x] **n/a-pass** — Motion guarded: no animations.
- [x] **pass** — Tests use `pumpAppFrames`, never `pumpAndSettle`.
- [x] **n/a-pass** — i18n: no keys of its own; `gen-check` unaffected.
- [x] **pass** — Strict-analysis clean: typed `CacheEntry<T>` generics, exhaustive `CacheStatus`
  switch, no `dynamic`; JSON (de)serialization behind typed factories.
- [ ] **warn** — Native entitlements: `FileCacheStore` writes to the app sandbox via
  `path_provider` (no entitlement on iOS/Android), but macOS sandboxed builds need the
  `Application Support` writable-container — verify in the macOS CI build job.
- [x] **n/a-pass** — Golden re-baseline: no UI; none required.

## Risks / notes

- **This feature escalates the no-backend boundary.** Per the source research, there is
  **deliberately no network/db/file-storage adapter today** (architecture.md: only
  `log_redactor` has tests; no network adapter exists by design). `FileCacheStore` is the first
  non-`SharedPreferences` persistence adapter — confirm with the architecture owner that a second
  storage port is sanctioned before building, since it sets the precedent for future file/db
  adapters. If declined, fall back to a `SharedPreferences`-backed JSON store with a documented
  payload-size cap.
- **Port reuse is mandatory.** The connectivity sensor is **shared** with
  [`connectivity`](connectivity.md) ([D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)).
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
  (shared port) and is most useful once a real data-source feature consumes it — no consumer is
  designated today ([`search-pagination`](search-pagination.md) defines its own `PageFetcher<T>` +
  `PagedState<T>` and does not consume `cachedFutureProvider`). No UI/golden impact of its own.
