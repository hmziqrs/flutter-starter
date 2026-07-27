# MFA / OTP completion

> **Tier:** P2 · **Domain:** security · **Backend:** test-server · **Status:** planned · **Depends on:** session

## Summary

Promotes the existing fixture OTP screen into a real multi-factor flow: a live expiry countdown, an `OtpPurpose.mfa` value for login verification, delivery-channel and verify ports, and optional TOTP/authenticator-app enrollment plus recovery codes. MFA is the standard mitigation for weak or leaked passwords and is mandatory in finance, health, and enterprise compliance regimes.

## Contract

- **Ports / value objects:**
  - `OtpRepository` abstract interface in `lib/features/auth/` (port) — `Future<OtpIssueResult> issue({required OtpPurpose purpose, required String identifier})`, `Future<OtpVerifyResult> verify({required String identifier, required String code})`, `Future<void> resend({required String identifier})`. Typed results: `OtpIssueResult` (`expiresAt`, `channel`, `attemptToken`), `OtpVerifyResult` (`valid` / `invalid` / `expired` / `locked`). Exceptions wrap into `OtpRepositoryException`; no success spoofing.
  - Extend [`OtpPurpose`](../../../lib/app/routing/otp_purpose.dart) with `mfa('mfa')` and its `tryParse` arm — today only `registration` and `passwordReset` exist.
  - Extend [`OtpPresentationState`](../../../lib/features/auth/otp_presentation_state.dart) with `remainingSeconds` (real expiry countdown; today `expired` is only a fixture). Add `OtpPresentationStatus.locked` for rate-limit handoff with [auth-ratelimit](auth-ratelimit.md).
  - `OtpController` handwritten Riverpod Notifier owning the expiry `Timer` and submit/resend state transitions (today the page is stateless and takes a fixed `OtpPresentationState`).
- **Providers:** handwritten Riverpod — `otpRepositoryProvider` (overridden at the App [`ProviderScope`](../../../lib/app/app.dart)), `otpControllerProvider` family keyed by `(OtpPurpose, identifier)`. No codegen. Mirrors the `settingsRepositoryProvider` shape exactly: unoverridden in a real build it throws; the production default is `InMemoryOtpRepository`.
- **Routes:** **no new route** — reuses [`AppRoutes.otp`](../../../lib/app/routing/app_routes.dart) + `AppRoutes.otpLocation(OtpPurpose.mfa)`. The router's `OtpPurpose.tryParse` already rejects unknown segments, so adding `.mfa` is the only routing change. No new redirect; the login flow calls `context.pushNamed(AppRoutes.otp, pathParameters: {'purpose': OtpPurpose.mfa.pathSegment})`.
- **Files:**
  - add `lib/features/auth/otp_repository.dart` (port + result types + exception)
  - add `lib/features/auth/in_memory_otp_repository.dart` (production default — surfaces `common.notConnected`)
  - add `lib/features/auth/otp_controller.dart` (Notifier + expiry Timer)
  - **edit** `lib/features/auth/otp_purpose.dart` (add `mfa` + parse arm)
  - **edit** `lib/features/auth/otp_presentation_state.dart` (`remainingSeconds`, `locked` status)
  - **edit** `lib/features/auth/otp_page.dart` (consume controller instead of static `presentation`; render countdown + locked state)
  - **edit** `lib/app/routing/app_router.dart` (wire `OtpPage` to the controller for `.mfa`)
  - **edit** `lib/app/dependencies.dart` + `lib/app/app.dart` (wire `otpRepositoryProvider` override) — **root composition**
  - optional add `lib/features/auth/totp/totp_enrollment.dart` (uses `package:otp`)
  - add `test/features/auth/otp_controller_test.dart`, `test/features/auth/in_memory_otp_repository_test.dart`
- **Dependencies:** `otp` (pub, optional — only for TOTP enrollment). Core flow needs no new package.

## Backend & test surface

Per [D2](../decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server):

- **Noop/InMemory production default:** `InMemoryOtpRepository` is constructed in [`AppDependencies.production`](../../../lib/app/dependencies.dart) and overridden at the `ProviderScope`. It runs green with **zero backend**; `issue`/`verify`/`resend` all surface `common.notConnected` via `OtpRepositoryException` and **never fake success** — the OTP screen stays a faithful static demo until a consumer wires a real impl.
- **Optional real impl:** `HttpOtpRepository` (a consumer-owned adapter in `lib/infrastructure/auth/`) is an **override** constructed only when a consumer wires credentials. It is never constructed by default; the starter ships without it.
- **`tools/test_server/` contract** ([D3](../decisions.md#d3--minimal-in-repo-test-server-tools-test_server)): the minimal Dart server implements the OTP route group:
  - `POST /v1/otp/issue` — body `{purpose: "mfa"|"registration"|"password-reset", identifier}` → `{attempt_token, expires_at, channel}` (channel is `"sms"`/`"email"`/`"authenticator"`; for tests the server also returns the code in a `dev_code` field **only** when the request carries the development API key).
  - `POST /v1/otp/verify` — body `{attempt_token, code}` → `{valid: bool}` or `409 {error: "expired"}` or `429 {error: "locked", retry_after_seconds}`.
  - `POST /v1/otp/resend` — body `{identifier, purpose}` → `{attempt_token, expires_at}` (rate-limited server-side).
  - Integration tests start the server on a random port and point `HttpOtpRepository` at it via override; the `development` config may point at a fixed local URL. The server is **never** compiled into release builds.
- **Fakes:** in-memory / `FakeAsync` for the controller's expiry Timer; `StreamController` for the repo if a stream API is added. **No Mocktail.**

## Tests

- **Unit/widget:** `in_memory_otp_repository_test.dart` asserts every method throws `OtpRepositoryException` (the no-backend honest-unavailable contract). `otp_controller_test.dart` uses `FakeAsync` to assert the countdown reaches 0 → emits `expired`, that `verify(invalid)` surfaces the field error, and that `locked` state gates the submit button exactly like the existing `_submitting` guard. Widget test renders the countdown and locked-out states in the localized harness.
- **Integration:** reuse `createApplication`; `pumpAppFrames`, **never** `pumpAndSettle`. A `mfa-otp` integration test starts the `tools/test_server/` on a random port, overrides `otpRepositoryProvider` with `HttpOtpRepository` pointed at it, and drives issue → enter code → verify → home.
- **Golden impact:** **yes** — the OTP canonical matrix case in [`canonical_matrix_golden_test.dart`](../../../test/goldens/canonical_matrix_golden_test.dart) gains a `mfa` purpose variant and a real-countdown state; requires a **re-baseline on the pinned macOS runner** via `--update-goldens`. Inspect the changed baseline (countdown text changes per second — pin a fixed `FakeAsync` value in the golden fixture so it is deterministic).
- **Dev-gallery fixture:** extend the existing OTP case set in [`production_gallery_cases.dart`](../../../lib/features/dev_gallery/cases/production_gallery_cases.dart) with `mfa` purpose and `locked` / countdown variants, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** extend `auth.otp.*` — add `mfaTitle`, `mfaBody`, `expiresIn(seconds:)` (plural-aware), `expiredTitle`, `expiredBody`, `resendIn(seconds:)`, `lockedTitle`, `lockedBody(seconds:)`. Sync across `en.i18n.json`, `ar.i18n.json`, `zh-Hans.i18n.json`; run `just gen`.
- **RTL note:** numeric countdown is LTR; titles follow `Directionality`. The `(seconds:)` interpolation must use slang plural rules per locale.

## Audit

- [x] No-backend honored as a port — **pass**: port + `InMemoryOtpRepository` default (surfaces `common.notConnected`, never fakes success) + optional `HttpOtpRepository` override + concrete `tools/test_server/` OTP contract.
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: port + state under `lib/features/auth/`; real impl under `lib/infrastructure/auth/`.
- [x] Shared/widgets extraction only if ≥3 consumers — **n/a**: reuses existing `OtpPage` + `AuthPageScaffold`; no new shared widget.
- [x] Motion guarded — **warn**: the countdown ring / progress and the success → navigate transition must be guarded by `MediaQuery.disableAnimationsOf(context)` with a fallback that still completes navigation (`context.goNamed`) when motion is disabled.
- [x] Tests use `pumpAppFrames`, never `pumpAndSettle` — **pass**.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: exhaustive switch over `OtpVerifyResult` / `OtpPresentationStatus`; no `dynamic`.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: OTP is pure network + UI; no native permission.
- [x] Golden re-baseline noted — **warn**: adds an `mfa` purpose variant + countdown state to the canonical matrix; requires `--update-goldens` on the pinned macOS runner with a fixed `FakeAsync` second.

## Risks / notes

- **Partly present.** [`otp_page.dart`](../../../lib/features/auth/otp_page.dart) + `OtpFormValue` + `OtpPresentationState` (incl. `invalid`/`expired`/`resending`/`submitting`, 6-digit validation, resend cooldown, `context.t` copy) already exist. This feature is a **deepening** (real expiry Timer + `.mfa` purpose + port), not a greenfield build — keep the existing fixture path working so the dev-gallery stays deterministic.
- **Rate-limit handoff.** `OtpPresentationStatus.locked` is set by the [auth-ratelimit](auth-ratelimit.md) `AttemptTracker`; the OTP controller reads it, the controller does **not** own retry policy. Build `auth-ratelimit` first or stub the tracker to avoid a circular dep.
- **TOTP enrollment is optional and gated.** `package:otp` is only pulled if a consumer opts into authenticator-app enrollment; recovery codes must be stored via [`SecureStore`](../decisions.md#d4--port-reuse-do-not-multiply-backends), never `SettingsStore`.
- **`dev_code` in the test server is a deliberate test affordance** — guard it behind the development API key so it can never leak into a staging/prod run, and never log it (verify against [log-redaction](log-redaction.md)).
- **Countdown determinism.** The expiry Timer must be injectable (`FakeAsync` / a `Clock` port) so unit + golden tests are not wall-clock flaky.
