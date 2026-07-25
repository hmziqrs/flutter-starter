# App lifecycle observer

> **Tier:** P0 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary

A `WidgetsBindingObserver` that publishes `AppLifecycleState` transitions (paused / resumed / inactive / hidden / detached) so the app can pause work when backgrounded and re-validate state on foreground. Foundational and backend-free: every resume-dependent feature (connectivity refresh, settings/locale re-sync, session token refresh, future auto-lock) hangs off the provider this exposes.

## Contract

- **Ports / value objects:** No port — Flutter SDK only. A typed `AppLifecyclePhase` value (wrapping `AppLifecycleState` plus a `transitionedAt` instant) so consumers switch on a stable enum, not a raw framework type.
- **Providers:** `appLifecycleStateProvider` — handwritten Riverpod (Notifier shape mirroring [`interactionPolicyProvider`](../../lib/app/interaction_policy_controller.dart)), overridden at the App `ProviderScope` only when tests need to inject a phase. Other features `ref.watch` it; nobody mutates it directly.
- **Routes:** none.
- **Files:**
  - `lib/app/app_lifecycle_controller.dart` — **new**, mirrors [`lib/app/interaction_policy_controller.dart`](../../lib/app/interaction_policy_controller.dart) (app-level composition, not a feature).
  - [`lib/app/app.dart`](../../lib/app/app.dart) — **edit**: `_AppViewState` mixes in `WidgetsBindingObserver` (`initState` → `addObserver`, `dispose` → `removeObserver`, `didChangeAppLifecycleState` pushes the phase into the controller).
- **Dependencies:** none (Flutter SDK `WidgetsBindingObserver`).

## Backend & test surface

Backend-free; the default impl **is** the real Flutter SDK binding — there is no port and no network. Tests inject transitions through the binding (`tester.binding` / a fake observer) rather than a plugin. This is a P0 foundation port in the [sequencing](../README.md#sequencing) sense (unblocks downstream features), not a D2 backend port.

## Tests

- **Unit/widget:** Controller publishes the correct phase for each `AppLifecycleState`; `addObserver`/`removeObserver` fire on mount/dispose of `_AppView`; no phase emitted after dispose.
- **Integration:** Reuse `createApplication`; `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`. Drive `AppLifecycleState.paused` → `resumed` via the test binding and assert the provider transitions.
- **Golden impact:** none — no UI.
- **Dev-gallery fixture:** n/a (no surface); optionally surface the current phase read-only on [`/dev/diagnostics`](../../lib/app/diagnostics/diagnostics_page.dart).

## i18n

- **Keys:** none.
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free Flutter SDK; nothing to fake.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: lives in `lib/app/` (composition root) like `interaction_policy_controller.dart`, not a feature — correct for app-level plumbing.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**: no widget.
- [x] Motion guarded — **n/a**.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**.
- [x] Strict-analysis clean — **pass**: typed `AppLifecyclePhase`, exhaustive switch on `AppLifecycleState`.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Golden re-baseline noted on pinned macOS runner — **n/a**.

## Risks / notes

- **Publish state, not behavior.** The observer's only job is to push `AppLifecyclePhase` into the provider. Resume-refresh / pause work belongs in the **consuming** features (connectivity, session, auto-lock), not here — do not grow this file into a dispatcher.
- **Gate resume work on `resumed` only.** `inactive`/`hidden` are noisy and fire on overlay/notifications; treat them as "going away", run re-validation only on the `resumed` edge.
- **Prerequisite** for [`connectivity`](connectivity.md) resume-refresh, [`session`](session.md) foreground token refresh, and the future [`pin-autolock`](pin-autolock.md) idle timer. Build first per the [sequencing](../README.md#sequencing).
- Only `didChangeAppLifecycleState` is overridden — leave `didHaveMemoryPressure` / metrics callbacks to future features that need them.
