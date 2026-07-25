# Roadmap decisions

Locked decisions governing the feature roadmap. Every feature doc under
[`features/`](features/) assumes these. Change a decision here first, then update the
affected feature docs and the [README](README.md) status table.

## D1 — Scope is comprehensive

The starter targets a **full, maximalist feature set** (~35 capabilities across startup,
foundation ports, core UX, security, engagement, and platform polish). Second-instances of a
pattern are kept (e.g. PIN *and* biometric *and* auto-lock) rather than collapsed into one
example, because the goal is a fork-and-ship product, not a single demonstration per pattern.

This overrides the lean/architecture-first instinct recorded in
[`docs/baseline_architecture_report.md`](../baseline_architecture_report.md), which bounded
abstractions to those with current callers. The roadmap introduces capabilities that have no
caller yet; each is gated by the audit checklist below so it still earns its place
structurally (port + Noop default + test surface), not by premature usage.

## D2 — Backend stance: port + Noop production default + optional real impl + test server

The starter stays **zero-backend in production by default**, but every backend-dependent
feature is built **for real** behind a four-part contract:

1. **Port** — an abstract interface mirroring [`SettingsStore`](../../lib/features/settings/settings_store.dart)
   (per-key, no `clearAll`, exceptions wrapped), owned under `lib/infrastructure/<area>/` with
   the value-object/state owned by the feature.
2. **Noop/InMemory (or real-local, e.g. a deterministic source) production default** — constructed in
   [`AppDependencies.production`](../../lib/app/dependencies.dart) and overridden at the
   `ProviderScope`. The app runs green with **zero backend**; actions needing one surface
   `common.notConnected` / `globalError` honestly and **never fake success** (the no-backend
   rule in [`architecture.md`](../../architecture.md) is load-bearing).
3. **Optional real impl** — the production adapter (Sentry, Firebase, a real HTTP client) is an
   **override** a consumer constructs only when they wire credentials. It is never constructed
   by default.
4. **Minimal test/dev server** at [`tools/test_server/`](D3) — a Dart server that implements the
   real contract so integration tests and the `development` config exercise actual network
   paths against a live (local) endpoint.

Rationale: this is the only stance that keeps the "runs green with zero setup" promise *and*
lets a forker flip features on by replacing one override. It resolves the long-open "how real
are backend features in a backend-free starter?" question.

## D3 — Minimal in-repo test server (`tools/test_server/`)

A small Dart server (shelf or dart_frog) lives under `tools/test_server/` and implements the
real backend contracts for dev runs and integration tests. It is **never compiled into release
builds** — it has no path into `lib/`, is not a Flutter dependency, and is excluded from
production targets.

- **Run:** a `just test-server` recipe starts it on a configurable port.
- **Wire:** integration tests start it on a random port and point the feature **real impls** at
  it via override; the `development` config may point at a fixed local URL.
- **Contracts implemented** (one route group per backend feature): version policy
  (min/latest + store URL) → [update-blocker](features/update-blocker.md); crash ingest →
  [crash-reporting](features/crash-reporting.md); auth issue/refresh/verify →
  [session](features/session.md); flags JSON → [feature-flags](features/feature-flags.md);
  events ingest → [analytics](features/analytics.md); OTP issue/verify →
  [mfa-otp](features/mfa-otp.md); feedback submit → [feedback](features/feedback.md);
  experiment assignments → [ab-experiments](features/ab-experiments.md); cache data source →
  [offline-cache](features/offline-cache.md).
- **Known limitation:** push (FCM/APNs) cannot be meaningfully mocked by a plain HTTP server.
  [push-notifications](features/push-notifications.md) is tested via `flutter_local_notifications`
  + a fake messaging repository; the test server covers the token-registration/permission path
  only.

## D4 — Port reuse (do not multiply backends)

Three port families are shared across features. Build each **once**; multiple features read it.

- **`ConnectivityService`** — one port under `lib/infrastructure/connectivity/`. The
  [connectivity](features/connectivity.md) banner and the future [offline-cache](features/offline-cache.md)
  both read it.
- **Remote-config family** — three **feature-owned typed ports**, each with its own `InMemory`
  default: `FeatureFlagsSource` ([feature-flags](features/feature-flags.md)),
  `VersionGateStore` ([update-blocker](features/update-blocker.md)), and `ExperimentSource`
  ([ab-experiments](features/ab-experiments.md)). The ports live **with their features**
  (`lib/features/{feature_flags,force_update,experiments}/`), mirroring the
  [`SettingsStore`](../../lib/features/settings/settings_store.dart) exemplar (port-with-feature;
  only the production adapter lives under `lib/infrastructure/`). A single **optional** real-impl
  adapter under `lib/infrastructure/remote_config/` wraps the remote-config backend
  (firebase_remote_config / GrowthBook) and exposes `flags` / `versionPolicy` / `experiments`
  slices that the three ports' real impls read from — one backend, three typed surfaces, three
  `InMemory` defaults. (Test-server shape in [D9](#d9--test-server-route-conventions).)
- **`SecureStore`** — one port under `lib/infrastructure/secure_storage/` for every secret:
  refresh tokens, PIN/biometric hashes, analytics opt-in, any future key.

Two more plug into **existing** seams rather than adding wiring:

- **Crash reporting** hooks [`_installErrorHandlers`](../../lib/bootstrap.dart) alongside
  `AppLogger.error`.
- **Analytics** screen-views come from a `GoRouter` `observers:` entry in
  [`buildAppRouter`](../../lib/app/routing/app_router.dart) — zero per-page edits.

## D5 — One `go_router` redirect pattern, reused

The router currently has **no redirect**. The first feature that needs one
([update-blocker](features/update-blocker.md) hard block, or
[onboarding-gate](features/onboarding-gate.md)) establishes the redirect helper in
[`buildAppRouter`](../../lib/app/routing/app_router.dart). Subsequent gates —
[session](features/session.md), [biometric](features/biometric.md),
[pin-autolock](features/pin-autolock.md) — reuse it. Do not invent per-feature redirect
mechanisms.

## D6 — No runtime environment switcher

Config is compile-time only via `--dart-define-from-file=config/<env>.json`
([`AppConfig`](../../lib/app/config/app_config.dart) hard-rejects `enable*` under production;
no runtime env fallback). A runtime env switcher is **rejected** — it violates this rule. The
[`/dev/diagnostics`](../../lib/app/diagnostics/diagnostics_page.dart) page already shows the
active environment read-only; switching environments means relaunching with a different define
file.

## D7 — Status lifecycle

Every feature doc carries a `Status:` field in its header, one of: `planned` →
`in-progress` → `done` (or `blocked`). The [README](README.md) status table mirrors it. Update
the feature doc header **and** the README row together when status changes; keep both in sync
so the table is the single live view of progress.

## D8 — Relationship to existing docs

- [`plans/feature_contracts.md`](../../plans/feature_contracts.md) freezes **current** feature
  public APIs. New features get a contract entry there before their public surface is finalized;
  this roadmap is the *intake* list, feature_contracts is the *freeze*.
- [`docs/baseline_architecture_report.md`](../baseline_architecture_report.md) records kept/
  rejected abstractions for the **existing** baseline; D1 amends its "deferred" stance for new
  roadmap work.
- [`docs/release_readiness.md`](../release_readiness.md) tracks release blockers (signing,
  brand assets, real credentials, device sign-off) — orthogonal to this roadmap but referenced
  by backend features' "optional real impl" step.

## D9 — Test-server route conventions

The `tools/test_server/` ([D3](#d3--minimal-in-repo-test-server-tools-test_server)) exposes a
stable, documented route table so every `server` feature's real impl points at a known endpoint
and integration tests are deterministic.

- **Uniform `/v1/` prefix** for all app-facing routes (versioning headroom).
- **One combined remote-config endpoint** — `GET /v1/remote-config?deviceId=&platform=&version=`
  returns `{flags, versionPolicy, experiments, revision}` in a single cacheable response. The
  three remote-config readers ([feature-flags](features/feature-flags.md),
  [update-blocker](features/update-blocker.md), [ab-experiments](features/ab-experiments.md))
  each read their slice from this one response — one round-trip, one cache. `If-None-Match` /
  `?rev=` → `304` when unchanged.
- **Other routes:** `POST /v1/crashes` ([crash-reporting](features/crash-reporting.md));
  `POST /v1/auth/{issue,refresh,logout}` ([session](features/session.md));
  `POST /v1/events` ([analytics](features/analytics.md)); `POST /v1/otp/{issue,verify}`
  ([mfa-otp](features/mfa-otp.md)); `POST /v1/feedback` ([feedback](features/feedback.md));
  `GET/PUT /v1/cache/{key}` ([offline-cache](features/offline-cache.md)).
- **Push** ([push-notifications](features/push-notifications.md)) has no plain-HTTP route —
  token registration/permission only; message delivery is tested via
  `flutter_local_notifications` + a fake messaging repo ([D3](#d3--minimal-in-repo-test-server-tools-test_server) limitation).
- **Never** compiled into release builds; integration runs bind a random port.
