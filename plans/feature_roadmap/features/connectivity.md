# Real-time connectivity indicator

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** [lifecycle-observer](lifecycle-observer.md) (resume-refresh)

## Summary

A live banner plus transition toasts that surface online/offline/limited state, driven by a stream of network changes. The app already ships `common.notConnected` and mounts `FToaster` at the root; this feature adds the missing live stream and a persistent surface so users understand *why* actions fail during dropouts instead of guessing.

## Contract

- **Ports / value objects:**
  - `ConnectivityState` enum (`online` / `offline` / `limited`) with an exhaustive `fromResult` factory over `connectivity_plus`'s `ConnectivityResult`.
  - `ConnectivityService` abstract port — `Stream<ConnectivityState> get states` + `ConnectivityState current`. Lives under `lib/infrastructure/connectivity/` because it is a **cross-feature** port (the banner and the future [offline-cache](offline-cache.md) both read it — [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)).
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

Backend-free — the default impl **is** the real `connectivity_plus` sensor (local platform API, no network round-trip). Tests use a `StreamController`-backed fake implementing `ConnectivityService` (mirrors [`InMemorySettingsStore`](../../lib/features/settings/in_memory_settings_store.dart); **no Mocktail**). [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends): one `ConnectivityService` port, shared with [offline-cache](offline-cache.md) later — build it once here.

## Tests

- **Unit/widget:** `ConnectivityState.fromResult` is exhaustive over every `ConnectivityResult`; banner renders for `offline`/`limited` and hides for `online`; controller emits correct transitions from a fake stream; resume-refresh re-arms on `resumed` from [lifecycle-observer](lifecycle-observer.md).
- **Integration:** Reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`. Override the provider with a `StreamController` fake, emit transitions, assert banner appears/dismisses and that a toast fires on the `online`↔`offline` edge.
- **Golden impact:** **yes** — the banner adds a row above the shell. Re-baseline the compact/expanded matrix on the pinned macOS runner ([`test/goldens/README.md`](../../test/goldens/README.md); baselines are currently empty — first run needs `--update-goldens`).
- **Dev-gallery fixture:** `PreviewFrame` cases for `online` / `offline` / `limited`, gated behind `developmentToolsEnabled` ([`lib/features/dev_gallery/preview_frame.dart`](../../lib/features/dev_gallery/preview_frame.dart)).

## i18n

- **Keys:** add a `connectivity` namespace — `connectivity.online`, `connectivity.offline`, `connectivity.backOnline`, `connectivity.limited` — synced across `en` + `ar` (RTL) + `zh-Hans`, then `just gen`.
- **RTL note:** banner is full-width and largely direction-agnostic, but re-check any status icon / chevron mirroring under `ar`.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free; default is the real local sensor, never fakes a result.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: port under `lib/infrastructure/connectivity/` (cross-feature per [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)), UI under `lib/features/connectivity/`.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**: banner stays feature-local; the port (not the widget) is the shared surface.
- [x] Motion guarded — **pass**: any sonar/pulse on the banner **and** the `ConnectivityBanner` enter/exit (appear on offline, dismiss on online) source durations/curves from [`AppMotion`](../../lib/shared/motion/app_motion.dart) and guard with `MediaQuery.disableAnimationsOf(context)` + a non-animated fallback that still toggles visibility.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: typed `ConnectivityState`, exhaustive `fromResult`, no `dynamic`.
- [x] Native entitlements flagged in PR + CI platform jobs — **warn**: macOS App Sandbox may need the `com.apple.security.network.client` entitlement for `connectivity_plus` to observe reachability; confirm and flag in the PR + macOS CI job.
- [x] Golden re-baseline noted on pinned macOS runner — **warn**: banner shifts the shell layout; re-baseline required.

## Risks / notes

- **Mount the banner in `app.dart`'s `builder:`, not inside `AppShell`.** Auth/onboarding are top-level routes outside the `ShellRoute`; a banner mounted only in the shell disappears exactly when a user is trying to authenticate over a dead link.
- **Hybrid surface** — a transient `FToaster` toast on the `online`↔`offline` **transition** (non-blocking, auto-dismiss) **plus** a persistent `ConnectivityBanner` for sustained offline. Do not double up: toast on every rebuild is noise.
- **No direct `connectivity_plus` calls in widgets.** Every read goes through the `ConnectivityService` port — that is what keeps `PreviewFrame` and integration tests hermetic (fake stream, no platform plugin).
- **Resume-refresh needs [lifecycle-observer](lifecycle-observer.md):** on `resumed`, re-read `current` and re-seed the stream — platform state may have changed while backgrounded.
- **Port-reuse ([D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)):** [offline-cache](offline-cache.md) will read this same `ConnectivityService` — do not build a second connectivity sensor there.
