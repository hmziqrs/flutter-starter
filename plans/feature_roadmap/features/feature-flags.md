# Feature flags / remote-config

> **Tier:** P1 · **Domain:** infra · **Backend:** test-server · **Status:** planned · **Depends on:** none

## Summary

Runtime toggles and injected config values that decouple app release from feature rollout —
kill-switches, staged rollouts, dark launch. Ships a typed `FeatureFlags` value object and one
remote-config port family that [`update-blocker`](update-blocker.md) (`VersionGateStore`) and
[`ab-experiments`](ab-experiments.md) both reuse, so the roadmap does **not** end up with three
parallel remote sources ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)).

## Contract

- **Ports / value objects:**
  - `FeatureFlags` immutable value object — typed booleans/strings/numbers per known flag key,
    exhaustive getters, `FeatureFlags.defaults()` for the no-backend baseline. Mirror
    [`SettingsState`](../../../lib/features/settings/settings_state.dart) shape.
  - `FeatureFlagsSource` abstract port — `Future<FeatureFlags> load()` +
    `Stream<FeatureFlags> changes()`. Throwing `FeatureFlagsException`.
- **Providers:**
  - `featureFlagsControllerProvider` — handwritten Riverpod `Notifier<FeatureFlags>` (no
    codegen), modeled on [`SettingsController`](../../../lib/features/settings/settings_controller.dart).
  - `featureFlagsSourceProvider` — `Provider<FeatureFlagsSource>` throwing `StateError` if
    unoverridden (same shape as `settingsRepositoryProvider`); default is the in-memory source.
- **Routes:** none.
- **Files:**
  - `lib/features/feature_flags/feature_flags.dart` (value object + enums)
  - `lib/features/feature_flags/feature_flags_source.dart` (port +
    `FeatureFlagsException`)
  - `lib/features/feature_flags/feature_flags_controller.dart`
  - `lib/features/feature_flags/in_memory_feature_flags_source.dart` (default — returns
    `FeatureFlags.defaults()`)
  - `lib/infrastructure/remote_config/remote_config_feature_flags_source.dart` (optional real
    impl — reads the `flags` slice from the shared remote-config backend per [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends))
  - **EDIT** `lib/app/dependencies.dart` — wire in-memory default + optional real
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - **EDIT** `lib/app/diagnostics/diagnostics_page.dart` — surface current flag state
    read-only, gated by `developmentToolsEnabled`
  - `test/features/feature_flags/feature_flags_controller_test.dart`
  - `test/features/feature_flags/in_memory_feature_flags_source_test.dart`
- **Dependencies:** `firebase_remote_config`, `growthbook_sdk`, or
  `launchdarkly_client_sdk` — **optional**, declared but not constructed unless the consumer
  wires credentials. The port + in-memory default need no package.

## Backend & test surface

- **Production default = `InMemoryFeatureFlagsSource`** — returns `FeatureFlags.defaults()`,
  runs green with zero backend, emits no changes. The default never claims a flag is enabled
  when the baseline says disabled (the [honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)
  is satisfied because flags have no user-facing success state).
- **Optional real impl** — `RemoteConfigFeatureFlagsSource` wraps Firebase Remote Config /
  GrowthBook / LaunchDarkly, constructed in `AppDependencies.production` only when the
  consumer wires credentials. Refresh under `config.verboseLoggingEnabled` or
  `developmentToolsEnabled` only; production builds fetch once and cache.
- **Test server contract ([C3](../contracts.md#c3--minimal-in-repo-test-server),
  [C9](../contracts.md#c9--test-server-route-conventions))** — the shared
  `GET /v1/remote-config?deviceId=&platform=&version=` endpoint returns one combined
  `{ "flags": {...}, "versionPolicy": {...}, "experiments": {...}, "revision": int }` response;
  this feature reads the `flags` slice. `If-None-Match` / `?rev=` → `304` when unchanged. The
  integration test starts the server on a random port, points the real impl at it, flips a flag
  server-side, and asserts the controller emits the new value.
- **Fakes** — in-memory/test only, no Mocktail:
  `InMemoryFeatureFlagsSource` (with a `StreamController` for changes) for unit tests; the test
  server for the live network path.

## Tests

- **Unit/widget:** `feature_flags_controller_test.dart` — initial value is
  `FeatureFlags.defaults()`; controller emits on `changes()` stream; getter accessors return
  typed values. `in_memory_feature_flags_source_test.dart` — `StreamController`-backed fake
  emits on demand.
- **Integration:** start `tools/hono_server/`, override `featureFlagsSourceProvider` with the
  real impl pointed at it, flip a flag, assert a downstream widget reacts. Use `pumpAppFrames`
  (8 frames), never `pumpAndSettle`.
- **Golden impact:** none for this feature itself; a gated UI change downstream may force a
  re-baseline (note that on the downstream feature's doc, not here).
- **Dev-gallery fixture:** n/a (no UI in this feature). Surface current flags on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) read-only so QA can
  verify state, gated by `developmentToolsEnabled`.

## i18n

- **Keys:** none (infra; no user-facing strings).
- **RTL note:** n/a.

## Audit

- [x] **No-backend honored as a port** — pass: in-memory default runs green, optional real
  impl is an override, test server contract defined, no faked success.
- [x] **Feature-first ownership; no core/ utils/ buckets** — pass: value object + port + controller
  + in-memory default under `lib/features/feature_flags/` (port lives with the feature, mirroring the
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) exemplar); the **optional real
  impl** (the shared remote-config backend adapter) under `lib/infrastructure/remote_config/`, shared
  in spirit with [`update-blocker`](update-blocker.md) + [`ab-experiments`](ab-experiments.md).
- [x] **shared/widgets extraction only if >=3 consumers** — n/a: no widget.
- [x] **Motion guarded** — n/a: no animation.
- [x] **Tests use pumpAppFrames, never pumpAndSettle** — pass: integration tests use the
  bounded-frame helper.
- [x] **i18n synced en/ar/zh-Hans; gen-check stays clean** — n/a: no strings.
- [ ] **Strict-analysis clean** — warn: `FeatureFlags` must use typed getters (no `dynamic`
  map of flags); every new flag is an enum/field with an exhaustive switch so analysis
  catches missing cases. Avoid `Map<String, Object>` on the public surface.
- [x] **Native entitlements flagged in PR + CI platform jobs** — n/a: no plugin; the optional
  Firebase SDK ships its own config the consumer wires.
- [x] **Golden re-baseline noted on pinned macOS runner** — n/a: no visual change.

## Risks / notes

- **Not the "port-family owner" — one of three peer readers ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)).**
  feature-flags owns the `FeatureFlagsSource` typed port; [`update-blocker`](update-blocker.md)
  (`VersionGateStore`) and [`ab-experiments`](ab-experiments.md) (`ExperimentSource`) own their
  **own** peer typed ports — three distinct types, three in-memory defaults, one optional shared
  real-impl adapter under `lib/infrastructure/remote_config/`. No feature "owns" the family and no
  shared interface is introduced; do not spin up a second remote-config client per feature.
- **Cache + fetch policy.** A flag read on the UI thread must never block on a network call.
  `FeatureFlagsController.build()` hydrates from the local cache synchronously (or
  `FeatureFlags.defaults()` if no cache), then refreshes asynchronously and emits. The
  optional real impl writes through to `SharedPreferences` or `SecureStore` for the cache —
  pick one and document it.
- **No `dynamic` flag bags.** Every flag is a typed field on `FeatureFlags`; adding a flag
  means extending the value object, updating `defaults()`, and (if gated in the UI) a
  consumer. This is what makes `flutter analyze --fatal-infos` catch missing branches.
- **Expose state on `DiagnosticsPage`** so QA can confirm which flags are active in a given
  build; gate the read-out behind `developmentToolsEnabled` (not exposed in prod).
- **Sequencing:** ship in the P1 "one port per pattern" bundle alongside
  [`session`](session.md) and [`analytics`](analytics.md). No UI, no golden impact.
