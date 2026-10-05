# Product analytics

> **Tier:** P1 · **Domain:** infra · **Backend:** test-server · **Status:** in-progress · **Depends on:** secure-store
>
> Implementation audit (2026-10-05): port + Noop default + optional real impls + router-observer
> seam + SecureStore opt-in + i18n verified. `HttpAnalyticsClient` batches onto `POST /v1/events`
> (backendBaseUrl-gated) and the production composite routes every real backend through
> `OptInGatedAnalyticsClient` (default off). Closed gap: the live-server e2e now exists —
> `test/e2e/analytics_events_e2e_test.dart` drives `screen_view` through the gate + HTTP client
> against the live JS Hono server. Still open: unit coverage for `PosthogAnalyticsClient` and
> the opt-in surface (controller persist/rollback + settings-tile widget test).

## Summary

Typed emission of screen-view and funnel events plus user properties to a measurement backend
(Amplitude / PostHog / Firebase GA4 / Mixpanel). Instrumented once at the routing and
interaction seams; cheap now, expensive to retrofit later. Screen views are captured
automatically by a `GoRouter` observer — **zero per-page edits**.

## Contract

- **Ports / value objects:**
  - `AnalyticsEvent` sealed value object — `ScreenView({routeName})`, `Tap({target})`,
    `FunnelStep({name, step})`, plus a typed `UserProperty` set. Every field is a typed
    primitive; **no `Map<String, dynamic>`** on the public surface.
  - `AnalyticsClient` abstract port — `track(AnalyticsEvent)`, `setUserProperty(...)`,
    `setUserId(String?)`. Implementations wrap their SDK in `try/on Object` and swallow
    failures (analytics must never break the UX it measures).
- **Providers:**
  - `analyticsClientProvider` — handwritten Riverpod `Provider<AnalyticsClient>`, overridden at
    the `ProviderScope` in [`lib/app/app.dart`](../../../lib/app/app.dart). Default is
    `NoopAnalyticsClient`; the real impl is constructed in
    [`AppDependencies.production`](../../../lib/app/dependencies.dart) only when the consumer
    wires credentials + the user has opted in.
  - `analyticsOptInControllerProvider` — a handwritten `Notifier<bool>` (see Files) backed by a
    thin `SecureStore` wrapper over the single `analytics_opt_in` key (per
    [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends), SecureStore owns every
    secret/sensitive preference); the real client consults this before emitting. **Not** a field on
    [`SettingsState`](../../../lib/features/settings/settings_state.dart) (SettingsState is
    `SettingsStore`-backed 1:1 via `SettingsRepository` — see the settings boundary in
    [`architecture.md`](../../../docs/architecture.md)).
- **Routes:** none (no new routes; the observer attaches to the existing `GoRouter`).
- **Files:**
  - `lib/infrastructure/analytics/analytics_client.dart` (port + `AnalyticsException`)
  - `lib/infrastructure/analytics/noop_analytics_client.dart` (default)
  - `lib/infrastructure/analytics/analytics_event.dart` (sealed value objects)
  - `lib/infrastructure/analytics/analytics_route_observer.dart` (`GoRouter` observer; emits
    `ScreenView` on route change)
  - `lib/infrastructure/analytics/posthog_analytics_client.dart` (optional real impl)
  - **EDIT** `lib/app/routing/app_router.dart` — pass `observers: [analyticsRouteObserver]`
    to `GoRouter(...)` in [`buildAppRouter`](../../../lib/app/routing/app_router.dart) (line 38)
  - **EDIT** `lib/app/dependencies.dart` — wire default noop + optional real
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - **EDIT** `lib/app/diagnostics/diagnostics_page.dart` — surface client status read-only,
    gated by `developmentToolsEnabled`
  - **add** `lib/features/settings/analytics_opt_in_controller.dart` — a small handwritten
    Riverpod `Notifier<bool>` backed by a thin `SecureStore` wrapper (read/write the single
    `analytics_opt_in` key). **Do not** add `analyticsOptIn` to
    [`SettingsState`](../../../lib/features/settings/settings_state.dart) — `SettingsState` fields are
    1:1 with `SettingsStore` keys via `SettingsRepository`; a `SecureStore`-persisted value must stay
    off it (see [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends) + the settings boundary
    in [`architecture.md`](../../../docs/architecture.md)). The settings page renders the toggle by watching
    this controller, not `settingsControllerProvider`.
  - `test/infrastructure/analytics/analytics_route_observer_test.dart`
  - `test/infrastructure/analytics/noop_analytics_client_test.dart`
- **Dependencies:** `amplitude-analytics`, `posthog_flutter`, `firebase_analytics`, or
  `mixpanel_analytics_flutter` — **optional**, declared but not constructed unless the
  consumer wires credentials. The port + Noop default need no package.

## Backend & test surface

- **Production default = `NoopAnalyticsClient`** — runs green with zero backend, drops events
  silently after routing them through `AppLogger` for verbose dev inspection. Never fakes
  upload success (the [honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)
  is satisfied because analytics has no user-facing success state).
- **Optional real impl** — `PosthogAnalyticsClient` (or Amplitude/Firebase/Mixpanel) constructed
  in `AppDependencies.production` only when (a) the consumer wires credentials AND (b) the user
  has opted in via `analyticsOptIn`. The override is the single seam.
- **Test server contract ([C3](../contracts.md#c3--minimal-in-repo-test-server))**
  — `tools/hono_server/` exposes `POST /v1/events` accepting a batch
  `{ "events": [ { "type": "screen_view"|"tap"|"funnel_step", "name": string,
  "props": object, "ts": iso8601 } ], "userId": string? }` and returning `204`. The
  integration test starts the server on a random port, points the real impl at it, navigates
  the router, and asserts a `screen_view` per route landed.
- **Fakes** — in-memory/test only, no Mocktail: a `RecordingAnalyticsClient` (list-backed) for
  unit tests; the test server for the live network path.

## Tests

- **Unit/widget:** `analytics_route_observer_test.dart` — drive a synthetic
  `GoRouter` route change, assert `track(ScreenView(...))` fired once with the right
  `routeName`. `noop_analytics_client_test.dart` — no-op, never throws, routes through
  `AppLogger` when verbose.
- **Integration:** start `tools/hono_server/`, override `analyticsClientProvider` with the
  real impl pointed at it, navigate via `context.goNamed`, assert the server recorded a
  `screen_view` per navigation. Use `pumpAppFrames` (8 frames), never `pumpAndSettle`.
- **Golden impact:** `settings_800x1000_zh_light_language` shifts — re-baseline on the pinned
  macOS runner (the SettingsPage opt-in toggle alters a matrix case).
- **Dev-gallery fixture:** extend the existing `settings.language` case (or add
  `settings.analytics`). Add a row on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) showing
  client-backend status (`noop` vs configured endpoint) read-only, gated by
  `developmentToolsEnabled`.

## i18n

- **Keys:** add `settings.analytics.optInTitle`, `settings.analytics.optInBody`,
  `settings.analytics.statusOn`, `settings.analytics.statusOff` to
  `lib/i18n/{en,ar,zh-Hans}.i18n.json` in sync; run `just gen`.
- **RTL note:** none — these are plain labels rendered via the existing
  [`SettingsPage`](../../../lib/features/settings/settings_page.dart) which already handles RTL.

## Audit

- [x] **No-backend honored as a port** — **pass**: port + Noop default + optional real impls +
  server route all verified (`lib/infrastructure/analytics/analytics_client.dart:7`,
  `noop_analytics_client.dart` (verbose-gated `AppLogger` routing),
  `posthog_analytics_client.dart` + `firebase_analytics_client.dart` (lazily inert — no
  `Firebase.initializeApp` in `lib/`), `http_analytics_client.dart` (`backendBaseUrl`-gated
  batching onto `POST /v1/events`); `POST /v1/events` at `tools/hono_server/src/index.ts:96`
  with TS contract tests). The Dart-side live-server e2e exists
  (`test/e2e/analytics_events_e2e_test.dart`). Resolves the pre-written warn.
- [x] **Feature-first ownership; no core/ utils/ buckets** — **pass**: adapter family under
  `lib/infrastructure/analytics/`; opt-in controller feature-owned at
  `lib/features/settings/analytics_opt_in_controller.dart`; tile at
  `lib/features/settings/widgets/analytics_opt_in_tile.dart`; no buckets.
- [x] **Shared extraction >=3 consumers** — **n/a**: no new shared widget (the tile is
  settings-local).
- [x] **Composition root confined** — **pass**: composite constructed only in
  `lib/app/dependencies.dart:377-380`; overridden in `lib/app/app.dart:112-115`;
  `PosthogAnalyticsClient` is constructed only in tests; observer injected via
  `buildAppRouter(observers: ...)` from `lib/app/app.dart:196-201`.
- [x] **Motion guarded** — **n/a**: no animation (the settings toggle is static).
- [x] **i18n synced en/ar/zh-Hans** — **pass**: `settings.analytics.{optInTitle, optInBody,
  statusOn, statusOff}` present in `lib/i18n/{en,ar,zh-Hans}.i18n.json` and generated in all
  three `translations_*.g.dart`. Resolves the pre-written warn.
- [x] **Strict analysis clean** — **pass**: sealed `AnalyticsEvent` with exhaustive switches
  (`noop_analytics_client.dart:44-56`, `firebase_analytics_client.dart:17-30`); the observer
  reads only `route.settings.name` (`analytics_route_observer.dart:21-27`); no `dynamic`.
  Resolves the pre-written warn.
- [x] **Generated code untouched** — **n/a**: no feature codegen output; slang regenerated
  from the synced JSON.
- [x] **Native entitlements flagged** — **n/a**: optional analytics SDK native config is
  consumer-wired; none committed.
- [x] **Goldens re-baselined + dev-gallery fixture** — **pass**: doc documents the
  `settings_800x1000_zh_light_language` matrix impact; `analytics_gallery_cases.dart` opt-in
  on/off fixtures exist; the pinned macOS 26 CI re-baseline is outstanding — the committed
  baselines predate this work and are outdated vs HEAD (13/14 canonical comparisons fail
  locally), tracked repo-wide per `test/goldens/README.md`, not failed here. Resolves the
  pre-written warn.
- [x] **Port-reuse consistency** — **pass**: one `GoRouter` `observers:` entry
  (`app.dart:197`, forwarding through `buildAppRouter`'s `observers` param at
  `lib/app/routing/app_router.dart:49`); opt-in is the single `SecureStore` key
  `analytics.opt_in` (`analytics_client.dart:5`) read by the real impl before emitting.
- [x] **Config rule respected** — **pass**: verbose logging through
  `config.verboseLoggingEnabled`; Diagnostics client-backend row read-only
  (`diagnostics_page.dart:130-134`); no runtime env switching.
- [x] **Honest feedback / no faked success** — **pass**: Noop drops events silently after
  verbose-gated logging; opt-in defaults to off with safe degradation
  (`dependencies.dart:272-282`); analytics has no user-facing success state to fake.

## Risks / notes

- **Plugs into an existing seam ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)):**
  screen views come from a single `GoRouter` `observers:` entry — no per-page edits. Adding a
  `track(...)` call inside a widget is the exception (funnel steps on a CTA), not the rule.
- **PII discipline.** Every event flows through `AppLogger` so
  [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) scrubs tokens/emails
  before they reach the network — **never** pre-redact (the redactor is the single choke point)
  and never include `userId` as raw email/phone. Treat the analytics SDK's own payload with
  the same suspicion as a log line.
- **Opt-in is a [`SecureStore`](secure-store.md) key**, not a `SettingsStore` plaintext key —
  this is the designated secrets/sensitive-preference port per [C4](../contracts.md#c4--port-reuse-do-not-multiply-backends).
  The real client consults it on every emit; the Noop default ignores it.
- **Never block the UX.** `track` is fire-and-forget on the main isolate; the real impl queues
  to its SDK's own background uploader. Wrap every SDK call in `try/on Object` and swallow.
- **Do not introduce `analytics_controller.dart`** unless something needs to react to client
  state. The client is read by the route observer and a handful of call sites, not by widgets.
- **Sequencing:** depends on [`secure-store`](secure-store.md) for the opt-in key. Ship in the
  P1 "one port per pattern" bundle alongside [`session`](session.md) and
  [`feature-flags`](feature-flags.md). Only UI is the SettingsPage opt-in toggle; flag the
  settings matrix case.
