# Product analytics

> **Tier:** P1 · **Domain:** infra · **Backend:** test-server · **Status:** planned · **Depends on:** secure-store

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
    [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends), SecureStore owns every
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
    off it (see [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends) + the settings boundary
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
  upload success (the [honest-feedback guardrail](../audit_checklist.md#13--honest-feedback-no-faked-success)
  is satisfied because analytics has no user-facing success state).
- **Optional real impl** — `PosthogAnalyticsClient` (or Amplitude/Firebase/Mixpanel) constructed
  in `AppDependencies.production` only when (a) the consumer wires credentials AND (b) the user
  has opted in via `analyticsOptIn`. The override is the single seam.
- **Test server contract ([D3](../decisions.md#d3--minimal-in-repo-test-server-tools-test_server))**
  — `tools/test_server/` exposes `POST /v1/events` accepting a batch
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
- **Integration:** start `tools/test_server/`, override `analyticsClientProvider` with the
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

- [x] **No-backend honored as a port** — pass: Noop default runs green, optional real impl is
  an override gated on opt-in, test server contract defined, no faked success.
- [x] **Feature-first ownership; no core/ utils/ buckets** — pass: port + observer + value
  objects under `lib/infrastructure/analytics/`; no buckets.
- [x] **shared/widgets extraction only if >=3 consumers** — n/a: no widget.
- [x] **Motion guarded** — n/a: no animation.
- [x] **Tests use pumpAppFrames, never pumpAndSettle** — pass: integration tests use the
  bounded-frame helper.
- [ ] **i18n synced en/ar/zh-Hans; gen-check stays clean** — warn: new opt-in strings must be
  added to all three locales together; `just gen-check` will fail CI if drifted.
- [ ] **Strict-analysis clean** — warn: `AnalyticsEvent` must be sealed with exhaustive
  switches per variant; the route observer must not surface `dynamic` route args (read only
  `state.name` / `state.uri.path`).
- [x] **Native entitlements flagged in PR + CI platform jobs** — n/a: no plugin beyond the
  optional analytics SDK whose own native config the consumer wires.
- [ ] **Golden re-baseline noted on pinned macOS runner** — warn: `settings_800x1000_zh_light_language`
  shifts from the SettingsPage opt-in toggle; re-baseline on the pinned macOS runner.

## Risks / notes

- **Plugs into an existing seam ([D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)):**
  screen views come from a single `GoRouter` `observers:` entry — no per-page edits. Adding a
  `track(...)` call inside a widget is the exception (funnel steps on a CTA), not the rule.
- **PII discipline.** Every event flows through `AppLogger` so
  [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) scrubs tokens/emails
  before they reach the network — **never** pre-redact (the redactor is the single choke point)
  and never include `userId` as raw email/phone. Treat the analytics SDK's own payload with
  the same suspicion as a log line.
- **Opt-in is a [`SecureStore`](secure-store.md) key**, not a `SettingsStore` plaintext key —
  this is the designated secrets/sensitive-preference port per [D4](../decisions.md#d4--port-reuse-do-not-multiply-backends).
  The real client consults it on every emit; the Noop default ignores it.
- **Never block the UX.** `track` is fire-and-forget on the main isolate; the real impl queues
  to its SDK's own background uploader. Wrap every SDK call in `try/on Object` and swallow.
- **Do not introduce `analytics_controller.dart`** unless something needs to react to client
  state. The client is read by the route observer and a handful of call sites, not by widgets.
- **Sequencing:** depends on [`secure-store`](secure-store.md) for the opt-in key. Ship in the
  P1 "one port per pattern" bundle alongside [`session`](session.md) and
  [`feature-flags`](feature-flags.md). Only UI is the SettingsPage opt-in toggle; flag the
  settings matrix case.
