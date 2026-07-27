# Crash & error reporting

> **Tier:** P0 · **Domain:** infra · **Backend:** test-server · **Status:** planned · **Depends on:** none

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
  overridden at the `ProviderScope` in [`lib/app/app.dart`](../../../lib/app/app.dart) — used by
  widget-side readers (the `DiagnosticsPage` status row). Default value is `NoopCrashReporter`
  (honors the no-backend boundary); a real impl is constructed in
  [`AppDependencies.production`](../../../lib/app/dependencies.dart) only when a consumer
  supplies a DSN. **The bootstrap error path does not read this provider** — `_installErrorHandlers`
  receives the reporter as a direct parameter (see Files), because it runs before the
  `ProviderScope` exists.
- **Routes:** none.
- **Files:**
  - `lib/infrastructure/error_reporting/crash_reporter.dart` (port + `CrashReport` value object)
  - `lib/infrastructure/error_reporting/noop_crash_reporter.dart` (production default)
  - `lib/infrastructure/error_reporting/sentry_crash_reporter.dart` (optional real impl)
  - **EDIT** `lib/bootstrap.dart` — thread the reporter as a parameter mirroring `AppLogger`:
    change the signature to `_installErrorHandlers(AppLogger logger, CrashReporter reporter)`
    (constructed in `bootstrap()` before the call — `NoopCrashReporter` by default, or the real
    impl when a DSN is configured). The body calls BOTH `logger.error(...)` AND
    `reporter.recordError(...)`. Do **not** `ref.read(crashReporterProvider)` here —
    `_installErrorHandlers` runs before `createApplication`/the `ProviderScope` exists
    (bootstrap.dart:20 vs :26), so there is no `ref` at the install site.
  - **EDIT** `lib/app/dependencies.dart` — wire default noop; optional real when DSN present
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - `test/infrastructure/error_reporting/crash_reporter_test.dart`
  - `test/infrastructure/error_reporting/noop_crash_reporter_test.dart`
- **Dependencies:** `sentry_flutter` (recommended real impl) or `firebase_crashlytics` —
  **optional**, declared but not constructed unless a consumer wires a DSN. No dep for the
  port or the Noop default.

## Backend & test surface

- **Production default = `NoopCrashReporter`** — runs green with zero backend, swallows errors
  silently after `AppLogger.error` has already logged them locally. It does **not** fake
  upload success (the [honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)
  is satisfied trivially because crash ingest has no user-facing success state).
- **Optional real impl** — `SentryCrashReporter` (or `FirebaseCrashReporter`) constructed in
  `AppDependencies.production` **only** when `AppConfig` exposes a DSN. The consumer flips one
  override; the default path never depends on a backend.
- **Test server contract ([C3](../contracts.md#c3--minimal-in-repo-test-server-tools-test_server))**
  — `tools/test_server/` exposes `POST /v1/crashes` accepting
  `{ "message": string, "stack": string?, "context": object, "platform": string,
  "appVersion": string }`, returning `204 No Content`. It stores the last N crashes in memory
  for inspection. The real-impl integration test starts the server on a random port, points
  `SentryCrashReporter` at it, forces a synthetic error through `_installErrorHandlers`, and
  asserts the ingest arrived.
- **Fakes** — in-memory/test only, no Mocktail: a `RecordingCrashReporter` (list-backed) for
  unit tests; the test server for the live network path.

## Tests

- **Unit/widget:** `crash_reporter_test.dart` exercises `NoopCrashReporter` (no-op, never
  throws) and `RecordingCrashReporter` capture; verifies `_installErrorHandlers(logger, reporter)`
  calls BOTH `logger.error` and `reporter.recordError`. Invoke `_installErrorHandlers` directly
  with fakes (`createApplication` does not install error handlers today), then drive a synthetic
  `FlutterError`/platform error.
- **Integration:** start `tools/test_server/`, override `crashReporterProvider` with
  `SentryCrashReporter` pointed at it, drive a synthetic throw via `createApplication`, assert
  the server recorded it. Use `pumpAppFrames` (8 frames), never `pumpAndSettle`.
- **Golden impact:** none.
- **Dev-gallery fixture:** n/a (no UI). Add a row on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) showing
  reporter-backend status (`noop` vs configured DSN host) read-only.

## i18n

- **Keys:** none (infra; no user-facing strings).
- **RTL note:** n/a.

## Audit

- [x] **No-backend honored as a port** — pass: Noop default runs green, optional real impl is
  an override, test server contract defined, no faked success.
- [x] **Feature-first ownership; no core/ utils/ buckets** — pass: under
  `lib/infrastructure/error_reporting/`, no buckets.
- [x] **shared/widgets extraction only if >=3 consumers** — n/a: no widget.
- [x] **Motion guarded** — n/a: no animation.
- [x] **Tests use pumpAppFrames, never pumpAndSettle** — pass: integration tests use the
  bounded-frame helper.
- [x] **i18n synced en/ar/zh-Hans; gen-check stays clean** — n/a: no strings.
- [ ] **Strict-analysis clean** — warn: `FlutterErrorDetails` and platform SDK errors arrive as
  `Object`; keep the port signature typed (`Object? error`, `StackTrace?`) and avoid `dynamic`
  in the value object — the redactor and the Sentry SDK both want `Object`.
- [x] **Native entitlements flagged in PR + CI platform jobs** — n/a: crash SDKs ship their own
  native config; surface the DSN requirement in the PR.
- [x] **Golden re-baseline noted on pinned macOS runner** — n/a: no visual change.

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
  path) and read via `crashReporterProvider` only by the `DiagnosticsPage` (widget path).
- **Sequencing:** ship in the P0 foundation bundle alongside
  [`secure-store`](secure-store.md) and the lifecycle observer — no UI, no golden impact, and
  it is the natural place to stand up [`tools/test_server/`](../contracts.md#c3--minimal-in-repo-test-server-tools-test_server)
  so every later `server` feature has a target.
