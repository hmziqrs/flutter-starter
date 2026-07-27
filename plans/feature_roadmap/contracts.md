# Feature contracts

The binding contracts every feature must satisfy. An implementer (or agent) reads this
alongside the feature spec in [`features/`](features/); every feature assumes these. To change a
contract, amend it here first, then update the affected feature docs and the [README](README.md)
status table.

## C1 — Scope is comprehensive

A **full feature set** (~35 capabilities across startup, foundation ports, core UX, security,
engagement, platform polish). Second-instances of a pattern are kept (e.g. PIN *and* biometric
*and* auto-lock) rather than collapsed into one example — the goal is a fork-and-ship product.
Capabilities with no caller yet are gated by the checklist below (port + Noop default + test
surface), not by premature usage.

## C2 — Backend stance: port + Noop production default + optional real impl + test server

The starter stays **zero-backend in production by default**, but every backend-dependent
feature is built **for real** behind a four-part contract:

1. **Port** — an abstract interface mirroring [`SettingsStore`](../../lib/features/settings/settings_store.dart)
   (per-key, no `clearAll`, exceptions wrapped), owned under `lib/infrastructure/<area>/` with
   the value-object/state owned by the feature.
2. **Noop/InMemory (or real-local, e.g. a deterministic source) production default** — constructed in
   [`AppDependencies.production`](../../lib/app/dependencies.dart) and overridden at the
   `ProviderScope`. The app runs green with **zero backend**; actions needing one surface
   `common.notConnected` / `globalError` honestly and **never fake success** (the no-backend
   rule in [`architecture.md`](../../docs/architecture.md) is load-bearing).
3. **Optional real impl** — the production adapter (Sentry, Firebase, a real HTTP client) is an
   **override** a consumer constructs only when they wire credentials. It is never constructed
   by default.
4. **Minimal test/dev server** at [`tools/test_server/`](#c3--minimal-in-repo-test-server-tools-test_server) — a Dart server that implements the
   real contract so integration tests and the `development` config exercise actual network
   paths against a live (local) endpoint.

## C3 — Minimal in-repo test server (`tools/test_server/`)

A small Dart server (shelf or dart_frog) lives under `tools/test_server/` and implements the
real backend contracts for dev runs and integration tests. It is **never compiled into release
builds** — it has no path into `lib/`, is not a Flutter dependency, and is excluded from
production targets.

- **Run:** a `just test-server` recipe starts it on a configurable port.
- **Wire:** integration tests start it on a random port and point the feature **real impls** at
  it via override; the `development` config may point at a fixed local URL.
- **Contracts implemented** (one route group per backend feature): version policy
  (min/latest + store URL) → [update-blocker](features/update-blocker.md); crash ingest →
  [crash-reporting](features/crash-reporting.md); auth issue/refresh/logout →
  [session](features/session.md); flags JSON → [feature-flags](features/feature-flags.md);
  events ingest → [analytics](features/analytics.md); OTP issue/verify/resend →
  [mfa-otp](features/mfa-otp.md); feedback submit → [feedback](features/feedback.md);
  experiment assignments → [ab-experiments](features/ab-experiments.md); cache data source →
  [offline-cache](features/offline-cache.md).
- **Known limitation:** push (FCM/APNs) cannot be meaningfully mocked by a plain HTTP server.
  [push-notifications](features/push-notifications.md) is tested via `flutter_local_notifications`
  + a fake messaging repository; the test server covers the token-registration/permission path
  only.

## C4 — Port reuse (do not multiply backends)

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
  `InMemory` defaults. (Test-server shape in [C9](#c9--test-server-route-conventions).)
- **`SecureStore`** — one port under `lib/infrastructure/secure_storage/` for every secret:
  refresh tokens, PIN/biometric hashes, analytics opt-in, any future key.

Two more plug into **existing** seams rather than adding wiring:

- **Crash reporting** hooks [`_installErrorHandlers`](../../lib/bootstrap.dart) alongside
  `AppLogger.error`.
- **Analytics** screen-views come from a `GoRouter` `observers:` entry in
  [`buildAppRouter`](../../lib/app/routing/app_router.dart) — zero per-page edits.

## C5 — One `go_router` redirect pattern, reused

The router already wires **one** top-level redirect — `_redirectSettingsDeepLinks` in
[`buildAppRouter`](../../lib/app/routing/app_router.dart) (settings deep-link normalization).
`go_router` accepts exactly one redirect callback, so every gating feature **composes its
predicate into that single helper** rather than adding a new one. The first feature that needs a
gate ([update-blocker](features/update-blocker.md) hard block, or
[onboarding-gate](features/onboarding-gate.md)) extends the existing helper; subsequent gates —
[session](features/session.md), [biometric](features/biometric.md),
[pin-autolock](features/pin-autolock.md) — chain into it. Do not invent per-feature redirect
mechanisms, and never overwrite the existing settings-deep-link redirect.

## C6 — No runtime environment switcher

Config is compile-time only via `--dart-define-from-file=config/<env>.json`
([`AppConfig`](../../lib/app/config/app_config.dart) hard-rejects `enable*` under production;
no runtime env fallback). A runtime env switcher is **rejected** — it violates this rule. The
[`/dev/diagnostics`](../../lib/app/diagnostics/diagnostics_page.dart) page already shows the
active environment read-only; switching environments means relaunching with a different define
file.

## C7 — Status lifecycle

Every feature doc carries a `Status:` field in its header, one of: `planned` →
`in-progress` → `done` (or `blocked`). The [README](README.md) status table mirrors it. Update
the feature doc header **and** the README row together when status changes; keep both in sync
so the table is the single live view of progress.

## C8 — Relationship to existing docs

- [`plans/feature_contracts.md`](../../plans/feature_contracts.md) freezes **current** feature
  public APIs. New features get a contract entry there before their public surface is finalized;
  this roadmap is the *intake* list, feature_contracts is the *freeze*.
- [`docs/baseline_architecture_report.md`](../../docs/baseline_architecture_report.md) records kept/
  rejected abstractions for the **existing** baseline; C1 amends its "deferred" stance for new
  roadmap work.
- [`docs/release_readiness.md`](../../docs/release_readiness.md) tracks release blockers (signing,
  brand assets, real credentials, device sign-off) — orthogonal to this roadmap but referenced
  by backend features' "optional real impl" step.

## C9 — Test-server route conventions

The `tools/test_server/` ([C3](#c3--minimal-in-repo-test-server-tools-test_server)) exposes a
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
  `POST /v1/events` ([analytics](features/analytics.md)); `POST /v1/otp/{issue,verify,resend}`
  ([mfa-otp](features/mfa-otp.md)); `POST /v1/feedback` ([feedback](features/feedback.md));
  `GET /v1/cache/{key}` ([offline-cache](features/offline-cache.md)).
- **Push** ([push-notifications](features/push-notifications.md)) has no message-delivery route
  (FCM/APNs cannot be mocked by a plain HTTP server) — only the token-registration/permission
  path: `POST /v1/notifications/register-token`, `DELETE /v1/notifications/register-token/{token}`,
  `POST /v1/notifications/permission-revoked`. Message delivery is tested via
  `flutter_local_notifications` + a fake messaging repo ([C3](#c3--minimal-in-repo-test-server-tools-test_server) limitation).
- **Never** compiled into release builds; integration runs bind a random port.


---

## Checklist — every feature must pass before `done`

Every feature doc and implementation must satisfy these guardrails. Re-run the list before marking a feature `done` in the [README](README.md) status table. For each item, mark the feature inline `## Audit` block `pass` / `warn` / `n/a` with a one-line reason; a feature is not `done` while any non-`n/a` item is `warn` or unverified.

### 1. No-backend honored as a port

Backend-dependent features ship **all four** parts of [C2](#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
port, Noop/InMemory production default (runs green, surfaces `common.notConnected`, never fakes
success), optional real override, and a `tools/test_server/` contract. Verify no widget calls a
plugin directly — every side effect goes through a port. Verify the Noop default does **not**
return success for an action that has no backend.

### 2. Feature-first ownership

Pages and typed `*_view_data` (+ `*_form_value` / `*_presentation_state` for forms) live under
`lib/features/<feature>/`. No `core/`, `utils/`, base-repository, use-case, or service-locator
layers. Cross-feature primitives go under `lib/shared/` only when a concern genuinely repeats.

### 3. Shared extraction threshold

Anything under `lib/shared/widgets/` or `lib/shared/forms/` needs **≥3 consumers** — concrete
today, or **designated** under [C1](#c1--scope-is-comprehensive): the feature doc
lists the ≥3 intended consumer features as deferred consumers and re-audits when they land
(demote to feature-local if they never materialize). This relaxes the baseline's strict
"current callers only" rule ([baseline report](../../docs/baseline_architecture_report.md)) for the
foundational UX primitives the comprehensive roadmap deliberately introduces. Pure-Dart
primitives under `lib/shared/state/` (e.g. `PagedStateNotifier`) need only **≥1 consumer + a
documented reuse intent** — the ≥3 bar is for widget/form extraction, not state helpers. Verify
proposed shared helpers meet the bar (concrete or designated); flag premature extraction with
no designated consumers.

### 4. Composition root confined

Providers wired only via `AppDependencies` + `ProviderScope` overrides in
[`lib/app/app.dart`](../../lib/app/app.dart). Concrete adapters constructed only in
[`lib/app/dependencies.dart`](../../lib/app/dependencies.dart),
[`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart), or
[`lib/bootstrap.dart`](../../lib/bootstrap.dart). No globals, no singletons, no plugin init
outside these three files (plus `main.dart`'s zone guard).

### 5. Motion guarded

Custom animations source durations/curves from [`AppMotion`](../../lib/shared/motion/app_motion.dart)
and guard with `MediaQuery.disableAnimationsOf(context)` **plus** a non-animated fallback that
still completes the action (e.g. `jumpToPage`/`goNamed`). Critical for splash, connectivity
sonar, banner enter/exit, pull-refresh, skeleton shimmer. Navigation must **never** gate on
animation completion — tests use [`pumpAppFrames`](../../integration_test/integration_test_support.dart)
(8 bounded frames), never `pumpAndSettle`.

### 6. i18n synced

All user-facing copy via `context.t`. New keys added to `en` + `ar` (RTL) + `zh-Hans`
**together**, then `just gen`; `just gen-check` stays clean. Verify RTL for any
direction-sensitive UI (banners, toasts, progress, chevrons). No hardcoded strings.

### 7. Strict analysis clean

Typed value objects, exhaustive `switch`, no `dynamic`/raw types. Handwritten Riverpod only —
**no** `riverpod_generator` / provider codegen introduced. `flutter analyze --fatal-infos`
passes (very_good_analysis + strict-casts/inference/raw-types + riverpod_lint).

### 8. Generated code untouched

Never hand-edit slang `*.g.dart` or ForUI `colors`/`typography`/`style`/`icons`/
`generated_forui_theme`. Change JSON/CLI sources and regenerate (`just gen` / `forui_cli`).
Accent colors via [`ForuiThemeFactory._accentColors`](../../lib/shared/theme/forui_theme_factory.dart).

### 9. Native entitlements flagged

Secure storage (Keychain/Keystore), biometric, deep links (associated-domains / `autoVerify` +
`assetlinks.json`), and push require per-platform native config **outside** `lib/`. The feature
doc's Risks section must call these out, and PRs + the CI platform jobs must cover them.

### 10. Goldens re-baselined

Visual features note golden re-baseline on the **pinned macOS runner**
([`test/goldens/README.md`](../../test/goldens/README.md); baselines are currently empty — first
run needs `--update-goldens`) **and** add a `dev_gallery` `PreviewFrame` fixture so the state is
deterministically previewable. Note which matrix cases change.

### 11. Port-reuse consistency

Confirm shared ports are shared, not duplicated: one `ConnectivityService` (banner + cache);
one remote-config family (flags + `VersionGateStore` + experiments); one `SecureStore` (all
secrets); crash into `_installErrorHandlers`; analytics into `GoRouter` `observers:`. Flag any
feature proposing a parallel port for a concern that already has one.

### 12. Config rule respected

No runtime environment switching (incompatible with compile-time
[`AppConfig`](../../lib/app/config/app_config.dart)). Behavior gated through
`verboseLoggingEnabled` / `developmentToolsEnabled`, never raw `enable*` flags. Dev-only
surfaces behind `if (config.developmentToolsEnabled)` at `/dev/*`.

### 13. Honest feedback, no faked success

Actions without a backend surface `common.notConnected` / `globalError` / `*Unavailable` via
the shared dialog helper and **never** claim success. No Mocktail fakes of backend success in
production code paths (in-memory fakes are for tests only and must surface the unavailable
state where the contract demands it).
