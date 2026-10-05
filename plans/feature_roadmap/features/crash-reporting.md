# Crash & error reporting

> **Tier:** P0 · **Domain:** infra · **Backend:** test-server · **Status:** done · **Depends on:** none
>
> Implementation audit (2026-10-04): port + Noop default + optional real impls + bootstrap
> threading verified. Remaining gap: the live-server crash-ingest integration test claimed in
> Tests below (Dart-side assert against `POST /v1/crashes`) does not exist — the route is
> covered only by the server's TS contract tests. Closed 2026-10-05 (see the audit box).
> Round 2 (2026-10-05): `bootstrap()` now installs the production composite (HTTP reporter
> whenever `backendBaseUrl` is set), and the reporter owns a timed transport so a hung
> backend cannot pin the crash POST.

## Summary

Captures unhandled Flutter framework errors and uncaught platform errors (with stack traces)
into a remote aggregator so field failures can be triaged. Near-zero friction:
[`lib/bootstrap.dart _installErrorHandlers`](../../../lib/bootstrap.dart) already funnels
`FlutterError.onError` + `PlatformDispatcher.instance.onError` — today it only calls
`AppLogger.error`. This port adds a second sink without inventing a new wiring pattern.

## Contract

- **Ports / value objects:** `CrashReporter` abstract interface —
  `recordError(Object error, StackTrace? stack, {Map<String, Object?> context})` and
  `recordFlutterError(FlutterErrorDetails details)`. Typed `CrashReport` value object carries
  the redacted message, optional stack (gated behind `verbose`), and structured context.
  Implementations wrap their SDK in `try/on Object` and **never rethrow** — crash reporting
  must not break the error path it is observing.
- **Providers:** `crashReporterProvider` handwritten Riverpod `Provider<CrashReporter`,
  overridden at the `ProviderScope` in [`lib/app/app.dart`](../../../lib/app/app.dart). It has
  **no widget readers today** — the `DiagnosticsPage` status row reads the sibling
  `crashReporterBackendProvider` — so it stays the widget-path override seam. Default is
  `NoopCrashReporter`; the real impl (`HttpCrashReporter`) is constructed in
  [`AppDependencies.production`](../../../lib/app/dependencies.dart) only when
  `AppConfig.backendBaseUrl` is set. **The bootstrap error path does not read this provider** —
  `_installErrorHandlers` receives the reporter as a direct parameter (see Files), because it
  runs before the `ProviderScope` exists.
- **Routes:** none.
- **Files:**
  - `lib/infrastructure/error_reporting/crash_reporter.dart` (port + `CrashReport` value object)
  - `lib/infrastructure/error_reporting/noop_crash_reporter.dart` (production default)
  - `lib/infrastructure/error_reporting/http_crash_reporter.dart` (wired real impl — dio,
    `POST /v1/crashes`)
  - `lib/infrastructure/error_reporting/sentry_crash_reporter.dart` (optional real impl)
  - **EDIT** `lib/bootstrap.dart` — thread the reporter as a parameter mirroring `AppLogger`:
    change the signature to `_installErrorHandlers(AppLogger logger, CrashReporter reporter)`
    (constructed in `bootstrap()` before the call — `NoopCrashReporter` plus the inert SDK
    impls; the wired `HttpCrashReporter` arrives in `AppDependencies.production`). The body calls BOTH `logger.error(...)` AND
    `reporter.recordError(...)`. Do **not** `ref.read(crashReporterProvider)` here —
    `_installErrorHandlers` runs before `createApplication`/the `ProviderScope` exists
    (bootstrap.dart:20 vs :26), so there is no `ref` at the install site.
  - **EDIT** `lib/app/dependencies.dart` — wire default noop; the real `HttpCrashReporter`
    when `backendBaseUrl` is configured
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - `test/infrastructure/error_reporting/crash_reporter_test.dart`
  - `test/infrastructure/error_reporting/noop_crash_reporter_test.dart`
- **Dependencies:** `dio` (the wired real impl — no new dependency); `sentry_flutter` or
  `firebase_crashlytics` for the optional SDK impls — declared but never constructed from a
  Dart config field (their native credentials are consumer-wired). No dep for the port or
  the Noop default.

## Backend & test surface

- **Production default = `NoopCrashReporter`** — runs green with zero backend, swallows errors
  silently after `AppLogger.error` has already logged them locally. It does **not** fake
  upload success (the [honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)
  is satisfied trivially because crash ingest has no user-facing success state).
- **Real impl — `HttpCrashReporter`** — constructed in `AppDependencies.production`
  **only when `AppConfig.backendBaseUrl` is set** (same signal as every other `/v1/*`
  client); POSTs the redacted `CrashReport` to `/v1/crashes` over its own tightly timed
  dio (mirroring the cache data source — crash POSTs are fire-and-forget from the error
  handlers, so an untimed shared client could pin them), never rethrows, and wires
  `RemoteCrashReporterBackend(host)` in the same branch so the
  diagnostics row shows the backend host. The SDK impls are not gated by any Dart config
  field — no `AppConfig` key carries a DSN; their native credentials are consumer-wired.
- **Test server contract ([C3](../contracts.md#c3--minimal-in-repo-test-server))**
  — `tools/hono_server/` exposes `POST /v1/crashes` accepting
  `{ "message": string, "stack": string?, "context": object, "platform": string,
  "appVersion": string }`, returning `204 No Content`. It stores the last N crashes in memory
  for inspection. The real-impl integration test starts the server on a random port, points
  `HttpCrashReporter` at it, forces a synthetic error through `_installErrorHandlers`, and
  asserts the ingest arrived.
- **Fakes** — in-memory/test only, no Mocktail: a `RecordingCrashReporter` (list-backed) for
  unit tests; the test server for the live network path.

## Tests

- **Unit/widget:** `crash_reporter_test.dart` exercises `NoopCrashReporter` (no-op, never
  throws) and `RecordingCrashReporter` capture; `http_crash_reporter_test.dart` covers the
  wire payload (verbose-gated stack), never-rethrow via a recording dio adapter, and the
  self-built transport's timeout path against a hung backend;
  `bootstrap_test.dart` asserts `_installErrorHandlers` calls BOTH `logger.error` (captured
  console sink) AND the reporter for every error source.
- **Integration:** `test/e2e/crash_ingest_e2e_test.dart` starts `tools/hono_server/` on a
  random port (graceful skip without a JS runtime), drives synthetic framework + platform
  errors through `installErrorHandlers` with an `HttpCrashReporter` on its own timed
  transport, and asserts the ingest on `GET /v1/crashes/last`. No widget pumping, no
  `pumpAndSettle`. `test/bootstrap_test.dart` additionally proves the full `bootstrap()`
  production path: with `backendBaseUrl` set, a framework error reaches the backend with
  no hand-wiring.
- **Golden impact:** none.
- **Dev-gallery fixture:** n/a (no UI). Add a row on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) showing
  reporter-backend status (`noop` vs configured backend host) read-only.

## i18n

- **Keys:** none (infra; no user-facing strings).
- **RTL note:** n/a.

## Audit

- [x] **No-backend honored as a port** — **pass** (2026-10-05): the 2026-10-04 audit's
  evidence plus the wired `HttpCrashReporter` and `test/e2e/crash_ingest_e2e_test.dart`.
- [x] **Feature-first ownership; no core/ utils/ buckets** — **pass**: no product screen;
  port + value object under `lib/infrastructure/error_reporting/` per C2's infra-area rule;
  no buckets.
- [x] **Shared extraction >=3 consumers** — **n/a**: no widget proposed.
- [x] **Composition root confined** — **pass** (2026-10-05, round 2): constructed only in
  `lib/bootstrap.dart:98-103` (boot-window pair) and `lib/app/dependencies.dart:369-378`
  / `:393-396` (both production branches); `bootstrap` re-arms the handlers with the
  production composite at `lib/bootstrap.dart:94`, so a configured backend needs no
  hand-wiring; overridden in `lib/app/app.dart:99-102`;
  `SentryCrashReporter` is constructed only in tests.
- [x] **Motion guarded** — **n/a**: no animation.
- [x] **i18n synced en/ar/zh-Hans** — **pass**: no feature-owned strings; the
  `diagnostics.crashReporting` label is synced in all three locales.
- [x] **Strict analysis clean** — **pass**: typed port signature
  (`recordError(Object, StackTrace?, {Map<String, Object?> context})`); `CrashReport`
  redaction via `LogRedactor` with verbose-gated stack (`crash_reporter.dart:37-51`); no
  `dynamic` in the area (grep clean). Resolves the pre-written warn.
- [x] **Generated code untouched** — **n/a**: no codegen output in this feature.
- [x] **Native entitlements flagged** — **pass**: crash SDK native config is consumer-wired;
  no `GoogleService-Info.plist`/`google-services.json` committed; DSN requirement stays in
  Risks.
- [x] **Goldens re-baselined + dev-gallery fixture** — **n/a**: no visual change; the
  `DiagnosticsPage` status row (`lib/app/diagnostics/diagnostics_page.dart:120-131`) is
  dev-only.
- [x] **Port-reuse consistency** — **pass**: hooks the existing error-handler seam
  (`installErrorHandlers`, `lib/bootstrap.dart:244-270`) alongside `AppLogger.error`; no
  parallel error sink; `CompositeCrashReporter` fans out and never rethrows
  (`composite_crash_reporter.dart:25-31`).
- [x] **Config rule respected** — **pass**: stack forwarding gated on
  `config.verboseLoggingEnabled` (`bootstrap.dart:101`, `dependencies.dart:375`); no runtime
  env switching.
- [x] **Honest feedback / no faked success** — **pass**: Noop swallows silently after local
  logging; crash ingest has no success state to fake; both-sink routing covered by
  `test/bootstrap_test.dart:117-210`.

## Risks / notes

- **Plugs into an existing seam ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)):**
  call the reporter **alongside** `AppLogger.error` inside `_installErrorHandlers`, do not
  replace it. `AppLogger` stays the local verbose-gated log; the reporter is the remote sink.
- **PII / double-redaction.** Reuse [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart)
  before forwarding context to the reporter; gate stack-trace forwarding behind
  `config.verboseLoggingEnabled` so a non-verbose build ships only the redacted message (the
  SDK's own native-bit redaction is not trusted to know the app's token formats). Never
  pre-redact — the redactor is the single choke point.
- **Never rethrow.** A reporter that throws inside `PlatformDispatcher.onError` can loop; wrap
  every SDK call in `try/on Object` and drop the report on failure.
- **Do not introduce `crash_reporter_controller.dart`** unless something needs to react to
  reporter state. The reporter is threaded as a parameter to `_installErrorHandlers` (bootstrap
  path); `crashReporterProvider` has no widget readers yet (the `DiagnosticsPage` reads the
  sibling `crashReporterBackendProvider` for its status row).
- **Sequencing:** ship in the P0 foundation bundle alongside
  [`secure-store`](secure-store.md) and the lifecycle observer — no UI, no golden impact, and
  it is the natural place to stand up [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server)
  so every later `server` feature has a target.
