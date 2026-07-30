# A/B experiment hooks

> **Tier:** P3 · **Domain:** engagement · **Backend:** test-server · **Status:** planned · **Depends on:** feature-flags, settings

## Summary

Assigns each user to an experiment variant and exposes that variant via a provider so UI or
behavior can branch on it — the substrate for data-driven product decisions and safe measured
rollouts. Built **on top of** the remote-config port family shared with feature flags and the
update blocker, not as a parallel subsystem, and runnable with zero backend via a deterministic
local source.

## Contract

- **Ports / value objects:** shares the **remote-config port family** with
  [`feature-flags`](feature-flags.md) and [`update-blocker`](update-blocker.md) per
  [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends) — one optional remote backend,
  three readers. Typed value objects under `lib/features/experiments/`: `ExperimentKey` (typed
  enum of known experiments), `ExperimentVariant` (`control`/`treatmentA`/… + payload `Map`,
  value-equality), `ExperimentAssignment` (`key` + `variant` + `sticky:bool` + `source` enum
  `local | remote`). Stable device identity = a salted hash persisted under one
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) key
  (`experiments.deviceStableId`); per-key discipline, **no** `clearAll`.
- **Providers:** handwritten Riverpod — `experimentSourceProvider` (overridden at the
  [`ProviderScope`](../../../lib/app/app.dart); `DeterministicExperimentSource` by default),
  `experimentsProvider(ExperimentKey key)` (family returning `AsyncData<ExperimentVariant>`),
  `experimentAssignmentsProvider` (the full snapshot, surfaced on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) under dev). Follow the
  [`SettingsController`](../../../lib/features/settings/settings_controller.dart) shape; **no**
  codegen.
- **Routes:** none — experiments have no surface of their own; they only gate existing UI.
- **Files:** feature-first —
  - `lib/features/experiments/experiment_key.dart`
  - `lib/features/experiments/experiment_variant.dart`
  - `lib/features/experiments/experiment_source.dart` (port — shared remote-config family)
  - `lib/features/experiments/experiments_controller.dart`
  - `lib/features/experiments/deterministic_experiment_source.dart` (production default)
  - `test/features/experiments/experiments_controller_test.dart`
  - **shared backend adapter (flagged):** experiments owns its own `ExperimentSource` typed port
    (above); the only shared piece is the optional real-impl adapter under
    `lib/infrastructure/remote_config/` per [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)
    (one backend, three peer typed ports — `FeatureFlagsSource` / `VersionGateStore` /
    `ExperimentSource`; no feature "owns" the family and no shared interface is introduced).
  - **root-composition edits (flagged):** [`lib/app/dependencies.dart`](../../../lib/app/dependencies.dart)
    (`AppDependencies.production` wires `DeterministicExperimentSource`),
    [`lib/app/app.dart`](../../../lib/app/app.dart) (`ProviderScope` override).
- **Dependencies:** none for the default (pure Dart hashing). Real-impl candidates
  (`growthbook_sdk`, `posthog_flutter`, `launchdarkly_client_sdk`) are **opt-in** — added to
  `pubspec.yaml` only when a consumer wires a remote source; the deterministic default keeps the
  dependency tree backend-free.

## Backend & test surface

Per [C2](../contracts.md#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
the starter runs green with **zero backend** and surfaces honest state — here that means sticky
local assignment, not faked remote data.

- **Deterministic production default** — `DeterministicExperimentSource` hashes the stable device
  id (from `SettingsStore`) per `ExperimentKey` into a variant bucket using a fixed allocation
  table. This is a **real** local assignment (not a Noop): it gives stable, reproducible variants
  with no network, so the UI can branch meaningfully without a backend. Constructed in
  `AppDependencies.production`.
- **Optional real override** — a remote-config-backed source (GrowthBook/PostHog/LaunchDarkly
  via the shared `ExperimentSource`/remote-config port) refreshes assignments under
  `verboseLoggingEnabled`/dev only; a consumer constructs it and overrides
  `experimentSourceProvider`. Never constructed by default; the remote source must degrade to the
  deterministic table when offline (read [`ConnectivityService`](connectivity.md)) rather than
  throwing.
- **Test-server contract** — [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server)
  implements the shared remote-config endpoint ([C9](../contracts.md#c9--test-server-route-conventions)):
  - `GET /v1/remote-config?deviceId=<stableId>&platform=<>&version=<>`
    -> `200 {experiments: {<key>: {variant, payload, sticky}}, flags: {...}, versionPolicy: {...}, revision: int}`
  - The single response serves experiments **and** feature flags **and** the update-blocker
    policy (one remote-config family, one cacheable response, one round-trip); `If-None-Match` / `?rev=` → `304`.
  Integration tests start the server on a random port and point the remote source at it; verify
  assignment stickiness across restarts with a fixed `deviceId`.
- **Fakes** — `InMemoryExperimentSource` (controllable per-key variant map) for controller
  tests, mirroring [`InMemorySettingsStore`](../../../lib/features/settings/in_memory_settings_store.dart).
  No Mocktail.

## Tests

- **Unit/widget:** `experiments_controller_test.dart` — deterministic bucketing is stable for a
  given device id and reproducible across controller rebuilds; allocation percentages hold over
  a large synthetic id set (statistical sanity, not a hard assertion); adding a new
  `ExperimentKey` does not re-bucket existing keys; remote-source failure degrades to the
  deterministic table without surfacing an error to the UI.
- **Integration:** reuse `createApplication`; point the remote source at `tools/hono_server` and
  assert stickiness across a cold restart with `pumpAppFrames` (8 bounded frames), **never**
  `pumpAndSettle`.
- **Golden impact:** **warn** — experiments have no UI of their own, but a variant that changes
  a visible surface (e.g. a different paywall layout) must be added as a `PreviewFrame` case and
  re-baselined on the pinned macOS runner. If the first experiment changes nothing visible,
  goldens are unaffected.
- **Dev-gallery fixture:** none required by default; if a variant changes a screen, add a
  `TypedGalleryCase` per variant behind `developmentToolsEnabled` via
  [`PreviewFrame`](../../../lib/features/dev_gallery/preview_frame.dart).

## i18n

- **Keys:** generally none — variants are behavioral, not user-facing copy. The only keys are
  the dev-only Diagnostics labels (`diagnostics.experiments.title`,
  `diagnostics.experiments.source`), already part of the diagnostics surface. If a variant
  changes user-facing copy, those keys belong to the **consuming** feature, not here.
- **RTL note:** n/a (no UI surface).

## Audit

- [x] **pass** — No-backend honored: `DeterministicExperimentSource` is a real local default
  (not a Noop); the optional remote source degrades to it offline. No faked remote data.
- [x] **pass** — Feature-first ownership: value objects + controller + source under
  `lib/features/experiments/`.
- [x] **n/a-pass** — Shared extraction: no `lib/shared/widgets/` proposal; this is a pure
  state/behavior feature.
- [x] **n/a-pass** — Motion guarded: no animations.
- [x] **pass** — Tests use `pumpAppFrames`, never `pumpAndSettle`.
- [x] **n/a-pass** — i18n: no user-facing keys of its own; `gen-check` unaffected.
- [x] **pass** — Strict-analysis clean: typed `ExperimentKey`/`ExperimentVariant` enums,
  exhaustive `switch` for variant handling, no `dynamic` in payloads (typed value objects).
- [x] **n/a-pass** — Native entitlements: none.
- [ ] **warn** — Golden re-baseline only if a variant changes a visible surface; otherwise n/a.
  Decide per-experiment.

## Risks / notes

- **Port reuse is mandatory, not optional.** Per [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends),
  experiments, [`feature-flags`](feature-flags.md), and [`update-blocker`](update-blocker.md)
  share **one** remote-config port family. Do not introduce a second remote source. If
  feature-flags lands first, adopt its source; if experiments lands first, expose the source so
  feature-flags and the update blocker can read it. Sequence this feature **after**
  [`feature-flags`](feature-flags.md) to avoid rework.
- **Sticky assignment integrity.** The stable device id is the contract — never rehash per
  session or variants flip on every launch. Persist it once in `SettingsStore`; if a user clears
  app data they may re-bucket, which is acceptable. Salt the hash so it is not reversible to a
  device fingerprint (the [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart)
  should also scrub `deviceId` if it ever appears in a log).
- **Do not gate critical paths on remote assignment.** Remote-config is best-effort; every
  `ref.watch(experimentsProvider(key))` must have a deterministic fallback (the local table) so
  the UI renders before the first remote response. Never block navigation on an experiment.
- **Variant exhaustiveness.** A new variant added to an `ExperimentKey` must compile-fail every
  consumer `switch` (strict `switch` over the variant enum) — this is the safety rail that
  prevents a silent default branch. Do not weaken it with a `default` case.
- **PII / logging.** Expose the current assignment snapshot on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) under
  `developmentToolsEnabled` only; never log assignment+deviceId together in production. Route
  through [`AppLogger`](../../../lib/infrastructure/logging/app_logger.dart).
- **Sequencing.** P3, ships last among the engagement ports; depends on
  [`feature-flags`](feature-flags.md) for the shared port and [`settings`](../README.md) for the
  stable id. No UI/golden impact unless a consuming feature introduces a visible variant.
