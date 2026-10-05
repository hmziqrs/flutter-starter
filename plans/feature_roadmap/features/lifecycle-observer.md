# App lifecycle observer

> **Tier:** P0 · **Domain:** startup · **Backend:** none · **Status:** in-progress · **Depends on:** none

> Implementation audit 2026-10-04: controller, provider, and `_AppView` observer wiring are
> implemented and the controller is unit-tested, but the doc's claimed observer-wiring widget test
> and binding-driven integration test do not exist yet (details in the Audit block) — hence
> `in-progress`, not `done`.

## Summary

A `WidgetsBindingObserver` that publishes `AppLifecycleState` transitions (paused / resumed / inactive / hidden / detached) so the app can pause work when backgrounded and re-validate state on foreground. Foundational and backend-free: every resume-dependent feature (connectivity refresh, settings/locale re-sync, session token refresh, future auto-lock) hangs off the provider this exposes.

## Contract

- **Ports / value objects:** No port — Flutter SDK only. A typed `AppLifecyclePhase` value (wrapping `AppLifecycleState` plus a `transitionedAt` instant) so consumers switch on a stable enum, not a raw framework type.
- **Providers:** `appLifecyclePhaseProvider` — handwritten Riverpod `NotifierProvider` mirroring [`settingsControllerProvider`](../../lib/features/settings/settings_controller.dart) (a real `Notifier`; **not** `interactionPolicyProvider`, which is a plain derived `Provider`), overridden at the App `ProviderScope` only when tests need to inject a phase. Other features `ref.watch` it; nobody mutates it directly.
- **Routes:** none.
- **Files:**
  - `lib/app/app_lifecycle_controller.dart` — **new**, mirrors [`lib/app/interaction_policy_controller.dart`](../../lib/app/interaction_policy_controller.dart) (app-level composition, not a feature).
  - [`lib/app/app.dart`](../../lib/app/app.dart) — **edit**: `_AppViewState` mixes in `WidgetsBindingObserver` (`initState` → `addObserver`, `dispose` → `removeObserver`, `didChangeAppLifecycleState` pushes the phase into the controller).
- **Dependencies:** none (Flutter SDK `WidgetsBindingObserver`).

## Backend & test surface

Backend-free; the default impl **is** the real Flutter SDK binding — there is no port and no network. Tests inject transitions through the binding (`tester.binding` / a fake observer) rather than a plugin. This is a P0 foundation port in the [sequencing](../README.md#sequencing) sense (unblocks downstream features), not a C2 backend port.

## Tests

- **Unit/widget:** Controller publishes the correct phase for each `AppLifecycleState`; `addObserver`/`removeObserver` fire on mount/dispose of `_AppView`; no phase emitted after dispose.
- **Integration:** Reuse `createApplication`; `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`. Drive `AppLifecycleState.paused` → `resumed` via the test binding and assert the provider transitions.
- **Golden impact:** none — no UI.
- **Dev-gallery fixture:** n/a (no surface); optionally surface the current phase read-only on [`/dev/diagnostics`](../../lib/app/diagnostics/diagnostics_page.dart).

## i18n

- **Keys:** none.
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free Flutter SDK; `AppLifecycleKind`/`AppLifecyclePhase` wrap the framework type with an exhaustive `_kindFromState` switch (`lib/app/app_lifecycle_controller.dart:49-57`); nothing to fake.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: lives in `lib/app/app_lifecycle_controller.dart` (app-level composition, peer of `interaction_policy_controller.dart`), not a feature or generic bucket.
- [x] shared/widgets extraction >=3 consumers — **n/a**: no widget extracted.
- [x] Composition root confined — **pass**: wiring confined to `_AppViewState` (`WidgetsBindingObserver` mixin, `addObserver`/`removeObserver`, `didChangeAppLifecycleState` → `transitionTo`, `lib/app/app.dart:191,216,275,281-286`); consumers only `ref.watch` (`connectivity`, `session`, `auto_lock`, `feature_flags`, `experiments` controllers + diagnostics).
- [x] Motion guarded — **n/a**: no animation.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**: no user-facing copy.
- [x] Strict-analysis clean — **pass**: typed `AppLifecyclePhase` (kind + `transitionedAt`, `==`/`hashCode`), exhaustive switch, no `dynamic` (`lib/app/app_lifecycle_controller.dart`).
- [x] Generated code untouched — **n/a**: no generated code in this feature.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: no native config.
- [x] Goldens re-baselined + dev-gallery fixture — **n/a**: no UI/golden surface; the optional read-only phase display landed on `/dev/diagnostics` (`lib/app/diagnostics/diagnostics_page.dart:88-90`).
- [x] Port-reuse consistency — **pass**: publish-state-only honored; one `appLifecyclePhaseProvider` read by all resume-dependent features via `lib/shared/state/app_lifecycle_listener.dart` (`listenOnResume`) — no parallel lifecycle sensors.
- [x] Config rule respected — **pass**: no env gating; SDK observer always on.
- [x] Honest feedback, no faked success — **n/a**: no backend action.
- [ ] Tests as claimed — **warn**: `test/app/app_lifecycle_controller_test.dart` covers every `AppLifecycleState` mapping, timestamping, and provider override (116 lines), and the resume edge is consumer-tested (`test/features/connectivity/connectivity_controller_test.dart:76`); but no test drives transitions through the binding/`_AppView` observer (the claimed "drive paused → resumed via the test binding" integration and "`addObserver`/`removeObserver` fire on mount/dispose of `_AppView`" widget assertions do not exist anywhere). Blocking `done`.

## Risks / notes

- **Publish state, not behavior.** The observer's only job is to push `AppLifecyclePhase` into the provider. Resume-refresh / pause work belongs in the **consuming** features (connectivity, session, auto-lock), not here — do not grow this file into a dispatcher.
- **Gate resume work on `resumed` only.** `inactive`/`hidden` are noisy and fire on overlay/notifications; treat them as "going away", run re-validation only on the `resumed` edge.
- **Prerequisite** for [`connectivity`](connectivity.md) resume-refresh, [`session`](session.md) foreground token refresh, and the future [`pin-autolock`](pin-autolock.md) idle timer. Build first per the [sequencing](../README.md#sequencing).
- Only `didChangeAppLifecycleState` is overridden — leave `didHaveMemoryPressure` / metrics callbacks to future features that need them.
