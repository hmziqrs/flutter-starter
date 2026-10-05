# Real-time connectivity indicator

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** done · **Depends on:** [lifecycle-observer](lifecycle-observer.md) (resume-refresh)

## Summary

A live banner plus transition toasts that surface online/offline/limited state, driven by a stream of network changes. The app already ships `common.notConnected` and mounts `FToaster` at the root; this feature adds the missing live stream and a persistent surface so users understand *why* actions fail during dropouts instead of guessing.

## Contract

- **Ports / value objects:**
  - `ConnectivityState` enum (`online` / `offline` / `limited`) with an exhaustive `fromResult` factory over `connectivity_plus`'s `ConnectivityResult`.
  - `ConnectivityService` abstract port — `Stream<ConnectivityState> get states` + `ConnectivityState current`. Lives under `lib/infrastructure/connectivity/` because it is a **cross-feature** port (the banner and the future [offline-cache](offline-cache.md) both read it — [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)).
- **Providers:** `connectivityServiceProvider` (handwritten, overridden at the App `ProviderScope`), `connectivityStatusProvider` (`StreamProvider` over the port, seeded with `current`). No codegen.
- **Routes:** none.
- **Files:**
  - `lib/features/connectivity/connectivity_state.dart`, `connectivity_controller.dart`, `connectivity_banner.dart` — **new** (state enum, Riverpod wiring, banner widget).
  - `lib/infrastructure/connectivity/connectivity_service.dart`, `connectivity_plus_service.dart` — **new** (abstract port + prod `connectivity_plus` adapter).
  - [`lib/app/dependencies.dart`](../../lib/app/dependencies.dart) — **edit**: construct `ConnectivityPlusService` in `AppDependencies.production`.
  - [`lib/app/app.dart`](../../lib/app/app.dart) — **edit**: override `connectivityServiceProvider` at the `ProviderScope` (peer of `settingsRepositoryProvider`) and mount `ConnectivityBanner` in the `MaterialApp.router` `builder:` **above** the router child so auth/onboarding keep the signal.
  - `lib/features/dev_gallery/cases/` — **edit**: add online/offline/limited preview cases.
- **Dependencies:** `connectivity_plus` (add as a direct dependency).

## Backend & test surface

Backend-free — the default impl **is** the real `connectivity_plus` sensor (local platform API, no network round-trip). Tests use a `StreamController`-backed fake implementing `ConnectivityService` (mirrors [`InMemorySettingsStore`](../../lib/features/settings/in_memory_settings_store.dart); **no Mocktail**). [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends): one `ConnectivityService` port, shared with [offline-cache](offline-cache.md) later — build it once here.

## Tests

- **Unit/widget:** `ConnectivityState.fromResult` is exhaustive over every `ConnectivityResult`; banner renders for `offline`/`limited` and hides for `online`; controller emits correct transitions from a fake stream; resume-refresh re-arms on `resumed` from [lifecycle-observer](lifecycle-observer.md).
- **Integration:** Reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`. Override the provider with a `StreamController` fake, emit transitions, assert banner appears/dismisses and that a toast fires on the `online`↔`offline` edge.
- **Golden impact:** **yes** — the banner adds a row above the shell. Re-baseline the compact/expanded matrix on the pinned macOS runner ([`test/goldens/README.md`](../../test/goldens/README.md); baselines are currently empty — first run needs `--update-goldens`).
- **Dev-gallery fixture:** `PreviewFrame` cases for `online` / `offline` / `limited`, gated behind `developmentToolsEnabled` ([`lib/features/dev_gallery/preview_frame.dart`](../../lib/features/dev_gallery/preview_frame.dart)).

## i18n

- **Keys:** add a `connectivity` namespace — `connectivity.online`, `connectivity.offline`, `connectivity.backOnline`, `connectivity.limited` — synced across `en` + `ar` (RTL) + `zh-Hans`, then `just gen`.
- **RTL note:** banner is full-width and largely direction-agnostic, but re-check any status icon / chevron mirroring under `ar`.

## Audit

- [x] No-backend honored as a port — **pass**: port `lib/infrastructure/connectivity/connectivity_service.dart`; the real `ConnectivityPlusService` sensor **is** the production default (`lib/app/dependencies.dart:405`), `StaticConnectivityService` is only the in-memory/gallery/integration default (`dependencies.dart:101`); stream/seed errors degrade to `offline` (`connectivity_plus_service.dart:36-39,87-92`) — never a faked success; no widget calls the plugin (only `connectivity_state.dart`'s type-level `fromResult` mapping, per contract).
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: UI/state under `lib/features/connectivity/{connectivity_state,connectivity_controller,connectivity_banner}.dart`; port + adapter under `lib/infrastructure/connectivity/` (cross-feature per [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)).
- [x] shared/widgets extraction >=3 consumers — **n/a**: banner stays feature-local; the port (not the widget) is the shared surface ([offline-cache](offline-cache.md) will read `ConnectivityService`).
- [x] Composition root confined — **pass**: providers overridden at the App `ProviderScope` (`lib/app/app.dart:96-98`); the service is constructed only in `dependencies.dart`; the banner mounts via `AppBannerHost` inside the `MaterialApp.router` `builder:` above the router child (`app.dart:407`, `lib/app/shell/app_banner_host.dart:32-44`).
- [x] Motion guarded — **pass**: offline pulse uses `AppMotion.deliberate` + `MediaQuery.disableAnimationsOf(context)` with a static-icon fallback (`connectivity_banner.dart:151-190`); banner show/hide is state-driven (`CollapsingBannerSlot`), not animation-gated.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**: `connectivity.{online,offline,backOnline,limited}` present in all three of `lib/i18n/{en,ar,zh-Hans}.i18n.json`.
- [x] Strict-analysis clean — **pass**: typed `ConnectivityState`, exhaustive `fromResult` over every `ConnectivityResult` value plus multi-result `fromResults` (`connectivity_state.dart:11-39`); no `dynamic`.
- [x] Generated code untouched — **pass**: no generated files in this feature.
- [x] Native entitlements flagged in PR + CI platform jobs — **pass** (warn resolved): `com.apple.security.network.client` is present in both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`; platform builds covered by `.github/workflows/release.yml` (apple job on `macos-26`).
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: `PreviewFrame` cases for online/offline/limited exist and are registered (`lib/features/dev_gallery/cases/connectivity_gallery_cases.dart`, `gallery_registry.dart:31`); the banner shifts the shell layout as documented in Tests — repo-wide re-baseline is outstanding (the committed baselines are outdated vs HEAD) (tracked repo-wide, not per-feature).
- [x] Port-reuse consistency — **pass**: one `ConnectivityService` (C4); banner + status read the same `connectivityStatusProvider`; resume-refresh re-arms via the shared lifecycle listener (`connectivity_controller.dart:14`, `lib/shared/state/app_lifecycle_listener.dart`).
- [x] Config rule respected — **pass**: no runtime env switching; gallery surface behind `developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: degradation is surfaced (persistent banner + back-online toast on the recovery edge, `connectivity_banner.dart:25-51`); sensor errors publish `offline` rather than a stale "online" (verified by `test/infrastructure/connectivity/connectivity_plus_service_test.dart`); `StaticConnectivityService` is never the production default.
- [x] Tests — **pass**: `connectivity_state_test.dart` (exhaustive mapping), `connectivity_controller_test.dart` (seeding, transitions, resume-refresh on the `resumed` edge only), `connectivity_banner_test.dart` (renders/hides per state, fires the back-online toast on the edge, bounded 8-frame pumps), `connectivity_plus_service_test.dart`; integration runs exercise the injection seam via `createApplication(connectivityService:)` (`integration_test/development_smoke_test.dart:87`, `production_routes_test.dart:33`).

## Risks / notes

- **Mount the banner in `app.dart`'s `builder:`, not inside `AppShell`.** Auth/onboarding are top-level routes outside the `ShellRoute`; a banner mounted only in the shell disappears exactly when a user is trying to authenticate over a dead link.
- **Hybrid surface** — a transient `FToaster` toast on the `online`↔`offline` **transition** (non-blocking, auto-dismiss) **plus** a persistent `ConnectivityBanner` for sustained offline. Do not double up: toast on every rebuild is noise.
- **No direct `connectivity_plus` calls in widgets.** Every read goes through the `ConnectivityService` port — that is what keeps `PreviewFrame` and integration tests hermetic (fake stream, no platform plugin).
- **Resume-refresh needs [lifecycle-observer](lifecycle-observer.md):** on `resumed`, re-read `current` and re-seed the stream — platform state may have changed while backgrounded.
- **Port-reuse ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)):** [offline-cache](offline-cache.md) will read this same `ConnectivityService` — do not build a second connectivity sensor there.
