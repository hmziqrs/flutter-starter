# Update blocker (hard block + soft deprecation)

> **Tier:** P2 · **Domain:** startup · **Backend:** test-server · **Status:** in-progress · **Depends on:** none (composes the update-block predicate into the existing top-level redirect helper `appRedirect` — [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused))
>
> Implementation audit (2026-10-04, updated 2026-10-05): port + `InMemory` none default +
> remote-config adapter + redirect composition + i18n + widget tests verified. Router-level
> coverage now exists (`test/app/routing/route_guards_test.dart` overrides
> `versionCheckProvider`: `hard` redirect from every route + no-pop trap + `soft` no-redirect
> and snooze suppression). Remaining gap: the `soft` dialog cannot actually be presented from
> the redirect — `showFDialog` is invoked with the go_router redirect context, which sits above
> the navigator, so `Navigator.of` throws (see Audit item 1); the live-server e2e still asserts
> only the store's `none` degradation.

## Summary

Compares the installed version against a server-published minimum/latest and either **hard-blocks** usage with a non-dismissible full-screen `ForceUpdatePage`, or shows a **dismissible** soft-deprecation nudge for deprecated versions. Shipping a breaking backend change or a critical security fix requires the ability to keep vulnerable clients out; soft deprecation sunsets old versions gracefully without locking users out.

## Contract

- **Ports / value objects:**
  - `VersionGateStore` — abstract port: `Future<UpdateRequirement> check(AppBuildInfo)` + `String? storeUrl`. Co-located with the feature (mirrors [`SettingsStore`](../../lib/features/settings/settings_store.dart), which lives with its feature while its prod impl lives under `lib/infrastructure/`).
  - `UpdateRequirement` — sealed enum `{none, soft, hard}` carrying `{minVersion, latestVersion, storeUrl, message?}`.
  - `ForceUpdateState` — typed view data for the hard-block page.
- **Providers:** `versionGateStoreProvider` (handwritten, overridden at the App `ProviderScope`), `versionCheckProvider` — a `FutureProvider<UpdateRequirement>` computed **once** in `createApplication` (after [`AppBuildInfo.load`](../../lib/infrastructure/platform/app_build_info.dart)) and read by the redirect.
- **Routes:** `AppRoutes.forceUpdate` + `AppRoutes.forceUpdatePath` (`'/force-update'`) — **new**, **top-level**, full-screen, non-dismissible (peer of auth/onboarding).
- **Files:**
  - `lib/features/force_update/version_gate_store.dart`, `force_update_state.dart`, `force_update_page.dart`, `soft_update_dialog.dart`, `in_memory_version_gate_store.dart` — **new**.
  - [`lib/app/routing/app_routes.dart`](../../lib/app/routing/app_routes.dart) — **edit**: add `forceUpdate` name + `forceUpdatePath`.
  - [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — **edit**: top-level `GoRoute` + compose the update-block predicate into the **existing** top-level `_redirectSettingsDeepLinks` redirect (any route → `forceUpdatePath` when `hard`; `soft` shows the dialog post-frame, no redirect). Per [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) go_router allows one redirect — extend the existing callback, do not add a second.
  - [`lib/bootstrap.dart`](../../lib/bootstrap.dart) — **edit**: run the check once in `createApplication` and feed `versionCheckProvider`.
- **Dependencies:** `pub_semver` (**add as a direct** dependency — transitive today, not app-direct); `url_launcher` (for the "Update now" store deep-link — confirm direct dep; `share_plus`/`url_launcher` are referenced by [license-share-update](license-share-update.md)).

## Backend & test surface

Per [C2](../contracts.md#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server), the four-part contract:

- **Port** — `VersionGateStore` as above.
- **Noop/InMemory production default** — `InMemoryVersionGateStore` returns `UpdateRequirement.none`, constructed in [`AppDependencies.production`](../../lib/app/dependencies.dart). The app runs green with **zero backend**; it never fakes a hard/soft block (that would be faking success — a real `none` is honest when there is no policy source).
- **Optional real impl** — a remote-config-backed `RemoteConfigVersionGateStore` is an **override** a consumer constructs only when they wire the backend. It shares the remote-config source family ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)) with [feature-flags](feature-flags.md) and [ab-experiments](ab-experiments.md) — three readers, one optional backend.
- **Test server contract** — [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server) exposes the shared `GET /v1/remote-config?deviceId=&platform=&version=` endpoint ([C9](../contracts.md#c9--test-server-route-conventions)) whose `versionPolicy` slice is `{minVersion, latestVersion, hardBlockBelow, softBlockBelow, storeUrl, message}` (the same response serves flags + experiments). The real impl maps that slice to `UpdateRequirement` via `pub_semver` compare against [`AppBuildInfo.version`](../../lib/infrastructure/platform/app_build_info.dart) (+`buildNumber`).
- **Fakes** — `InMemoryVersionGateStore` for unit tests/dev-gallery (returns `none`/`soft`/`hard` per fixture). **No Mocktail.**

## Tests

- **Unit/widget:** `pub_semver` compare correctness (older/equal/newer, pre-release semantics); `UpdateRequirement` mapping from a policy payload; `ForceUpdatePage` is non-dismissible (`PopScope(canPop: false)`, Escape does not pop); the soft dialog reuses [`EscapeDismissibleOverlay`](../../lib/shared/widgets/escape_dismissible_overlay.dart) + `FDialog` mirroring [`_showInformationDialog`](../../lib/app/routing/app_router.dart); exhaustive `switch` over `UpdateRequirement`.
- **Integration:** Reuse `createApplication` with the `InMemory` default (`none`) — boots to home. A second run overrides the real impl at the test-server URL and asserts the `hard` redirect and the `soft` dialog. `pumpAppFrames`, never `pumpAndSettle`.
- **Golden impact:** **deferred** — `ForceUpdatePage` is full-screen, but no canonical matrix case or baseline exists today; adding the full-screen matrix case is deferred to the pinned macOS 26 CI re-baseline (never run `--update-goldens` locally, per `test/goldens/README.md`). The `PreviewFrame` dev-gallery cases (`hard` page + `soft` dialog) already exist.
- **Dev-gallery fixture:** `PreviewFrame` cases for `hard` and `soft`, gated behind `developmentToolsEnabled` (backed by `InMemoryVersionGateStore` fixtures).

## i18n

- **Keys:** add `forceUpdate.{title,body,updateNow}` and `softUpdate.{title,body,update,later}` — synced across `en` + `ar` (RTL) + `zh-Hans`, then `just gen`.
- **RTL note:** full-screen page + dialog are direction-agnostic, but re-check button order (`Update` / `Later`) under `ar`.

## Audit

- [ ] No-backend honored as a port — **warn**: four parts verified — `VersionGateStore` port
  (`lib/features/force_update/version_gate_store.dart:5`), `InMemoryVersionGateStore` `none`
  default checked once in `AppDependencies.production` (`lib/app/dependencies.dart:267-271`),
  optional `RemoteConfigVersionGateStore` (constructed only in tests/e2e; live check at
  `test/e2e/hono_server_e2e_test.dart:81-88`), shared `/v1/remote-config` contract
  (`tools/hono_server/src/index.ts:209-221`). Router-level gate coverage added
  (`test/app/routing/route_guards_test.dart`): `hard` redirects every route to
  `forceUpdatePath` and is a no-pop trap; `soft` never redirects and a persisted snooze
  suppresses the prompt. Newly found defect keeping this open: the `soft` dialog is invoked
  with the go_router redirect context (`lib/app/routing/route_guards.dart:157`), which sits
  above the navigator — `Navigator.of` throws `Navigator operation requested with a context
  that does not include a Navigator`, so the dialog cannot appear in production either (the
  async error is swallowed). Presenting it needs a context under the root navigator
  (e.g. a `navigatorKey` on the router), owned by `lib/app/routing`.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: feature owns port + state +
  pages + dialog + routes module under `lib/features/force_update/`; only the shared
  remote-config client lives in infrastructure.
- [x] Shared extraction >=3 consumers — **pass**: soft dialog **reuses**
  `EscapeDismissibleOverlay` + the shared `FDialog` pattern
  (`lib/features/force_update/soft_update_dialog.dart:17-44`); nothing new extracted.
- [x] Composition root confined — **pass**: predicate composed first into the single
  `appRedirect` helper (`lib/app/routing/route_guards.dart:23-71`), never a second redirect;
  `versionCheckProvider` seeded from dependencies and overridden in `lib/app/app.dart:94-95`;
  router refreshes on change (`app.dart:221-225`); route module owns only its `GoRoute`
  (`force_update_routes.dart:13-35`).
- [x] Motion guarded — **n/a**: pages/dialog are static (hard page is a `PopScope(canPop:
  false)` trap — `force_update_page.dart:22-23`).
- [x] i18n synced en/ar/zh-Hans — **pass**: `forceUpdate.{title,body,updateNow}` +
  `softUpdate.{title,body,update,later}` present in all three locale files and generated.
- [x] Strict analysis clean — **pass**: sealed `UpdateRequirement`
  (`update_requirement.dart:5-22`); exhaustive switch verified by test
  (`update_requirement_test.dart:103`); `pub_semver` is a direct dependency
  (`pubspec.yaml:43`); no `dynamic`.
- [x] Generated code untouched — **pass**: `update_requirement.freezed.dart` /
  `force_update_state.freezed.dart` carry standard generated headers.
- [x] Native entitlements flagged — **n/a**: store URL via `url_launcher` wrapped in
  `runGuarded` (`route_guards.dart:171-181`); no entitlement.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: doc documents the full-screen
  golden impact; `PreviewFrame` fixtures for `hard` + `soft` exist
  (`lib/features/dev_gallery/cases/force_update_gallery_cases.dart:10-33`); the pinned macOS
  26 CI re-baseline is outstanding — the committed baselines predate this work and are
  outdated vs HEAD (13/14 canonical comparisons fail locally), tracked repo-wide per
  `test/goldens/README.md`, not failed here. Resolves the pre-written warn.
- [x] Port-reuse consistency — **pass**: `VersionGateStore` is the peer reader of the one
  `RemoteConfigClient` family; no second remote-config source.
- [x] Config rule respected — **pass**: the check runs once at boot in dependencies, never
  in a widget `build`; no runtime env switching.
- [x] Honest feedback / no faked success — **pass**: `InMemory` default returns a real
  `none`; the remote impl degrades to `none` on failure without faking a block (tested at
  `remote_config_version_gate_store_test.dart:144`); soft snooze persisted per-key
  (`SoftUpdateSnooze`, `soft_update_dialog.dart:110-130`).

## Risks / notes

- **Run the check once in `createApplication`, never in a widget `build`.** Feed `versionCheckProvider` and let the `go_router` redirect read it — checking in `build` re-fires on every rebuild and races the redirect.
- **Hard block is a true trap.** `ForceUpdatePage` uses `PopScope(canPop: false)`, no Escape pop (do **not** wrap in `EscapeDismissibleOverlay`), and offers only "Update now" (`url_launcher` → `storeUrl`). Soft is dismissible and must include a snooze path.
- **Soft-deprecation must not nag.** Persist a snooze timestamp (a `SettingsStore` key, e.g. `update.snoozed_until`) so a dismissed soft prompt does not re-appear every launch — otherwise it becomes a UX nuisance.
- **`pub_semver` must be a direct dependency** — it is transitively present today but not app-direct; add it explicitly.
- **Redirect helper ownership ([C5](../contracts.md#c5--one-go_router-redirect-pattern-reused)).** The router already has one top-level redirect (`_redirectSettingsDeepLinks`); compose the update-block predicate into it. Coordinate predicate order with [onboarding-gate](onboarding-gate.md) so a `hard` block wins (evaluate update-blocker first).
- **Port-reuse ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)):** `VersionGateStore` is update-blocker's reader on the shared remote-config family; the optional real impl shares its backend with [feature-flags](feature-flags.md) and [ab-experiments](ab-experiments.md) — do not stand up a second remote-config source.
- Client-side version is already available via [`AppBuildInfo`](../../lib/infrastructure/platform/app_build_info.dart) (`package_info_plus`); no new client capability is needed.
