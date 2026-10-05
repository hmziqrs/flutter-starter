# Auth rate-limit / lockout

> **Tier:** P2 · **Domain:** security · **Backend:** none · **Status:** in-progress · **Depends on:** none (consumers: mfa-otp, pin-autolock)

## Summary

Throttles repeated failed login / OTP / passcode attempts with per-identifier attempt counters, exponential cooldown, and a lockout countdown surfaced in the auth UI. Brute-force and credential-stuffing protection is expected on every login surface; a starter with none teaches an unsafe pattern.

## Contract

- **Ports / value objects:** `AttemptTracker` pure-Dart class in `lib/features/auth/` keyed by identifier — `AttemptState recordFailure(String identifier)`, `void recordSuccess(String identifier)`, `AttemptState? read(String identifier)`. Typed `AttemptState` (`attempts`, `lockedUntil`, `attemptsRemaining`, `nextCooldownSeconds`). Exponential backoff schedule is a `const` table (e.g. `→ [0, 0, 30, 60, 300, 900]` seconds) — no magic numbers at call sites. Optional persistence via [`SecureStore`](../../../lib/infrastructure/secure_storage/) (tamper-resistant) or in-memory only; the choice is injected, not hard-coded.
- **Providers:** handwritten Riverpod `attemptTrackerProvider` overridden at the App [`ProviderScope`](../../../lib/app/app.dart) through [`AppDependencies`](../../../lib/app/dependencies.dart) — tests override with a fresh in-memory tracker per group. No codegen.
- **Routes:** **none** — this is a pure domain/service, not a screen. No `AppRoutes` constants, no redirect.
- **Files:**
  - add `lib/features/auth/auth_attempt_tracker.dart` (tracker + `AttemptState` + cooldown table)
  - **edit** `lib/features/auth/login_presentation_state.dart` (add `attemptsRemaining`, `lockedSeconds` to `LoginPresentationState`)
  - **edit** `lib/features/auth/otp_presentation_state.dart` (add the same fields + reuse the new `locked` status from [mfa-otp](mfa-otp.md))
  - **edit** `lib/features/auth/login_page.dart` + `otp_page.dart` (render countdown, gate submit button like the existing `_submitting` guard)
  - **edit** `lib/app/dependencies.dart` + `lib/app/app.dart` (wire override) — **root composition**
  - add `test/features/auth/auth_attempt_tracker_test.dart`
- **Dependencies:** none (Flutter SDK). Pure Dart, no package.

## Backend & test surface

**Backend-free.** All counting, cooldown, and lockout logic is local. The default impl is real (`InMemoryAttemptTracker`), not a stub. No test-server contract; no `common.notConnected` path (a local lockout is authoritative for the local UX, see the note below). **Critical guardrail:** client-side throttling is UX / defense-in-depth **only** — authoritative enforcement is server-side. Treat this as a local complement, not the real gate; document the limitation in the tracker's doc comment so a forker does not mistake it for security.

## Tests

- **Unit/widget:** `auth_attempt_tracker_test.dart` — asserts the exponential schedule (`n` failures → expected `lockedSeconds`), that `recordSuccess` clears state, that an unknown identifier returns `null`, and that `lockedUntil` is honored (within `FakeAsync`). Widget test renders the login button disabled with `attemptsRemaining` + a live countdown in the localized harness.
- **Integration:** reuse `createApplication`; `pumpAppFrames`, **never** `pumpAndSettle`. Assert the submit button stays disabled while `lockedSeconds > 0` — covered in `integration_test/development_smoke_test.dart` (three failed submits through the login route lock the identifier; the submit `onPress` is `null` while the countdown runs).
- **Golden impact:** none — countdown text is timing-sensitive; do **not** add a canonical matrix case (would force per-second re-baselines for no signal). A static `locked` snapshot may be added to the dev-gallery only if pinned to a fixed second.
- **Dev-gallery fixture:** optional static `locked` variant of the login + OTP case in `production_gallery_cases.dart`, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** extend `auth.login.*` and `auth.otp.*` — `attemptsRemaining(count:)` (plural-aware), `lockedTitle`, `lockedBody(seconds:)`, `tooManyAttempts`. Sync across `en.i18n.json`, `ar.i18n.json`, `zh-Hans.i18n.json`; run `just gen`.
- **RTL note:** countdown numeric is LTR; titles follow `Directionality`. Plural form required for `count`.

## Audit

- [x] No-backend honored as a port — **pass** (2026-10-05): the mandated limitation now ships in
  the tracker's dartdoc — `AttemptTracker` documents that client-side throttling is UX /
  defense-in-depth only, never a security control, trivially bypassed, with authoritative
  enforcement server-side and a cooldown schedule the two sides must share
  (`lib/features/auth/auth_attempt_tracker.dart:6-24`); the cooldown table and the
  PII-hashed `InMemoryAttemptTracker` are documented alongside it.
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: tracker +
  `AttemptState` + const table in `lib/features/auth/auth_attempt_tracker.dart`; shared
  `VerificationLockoutPolicy` mixin in `verification_lockout_policy.dart`; no buckets.
- [x] Shared/widgets extraction only if ≥3 consumers — **pass**: login
  (auth_routes.dart:200), OTP (otp_controller.dart:53), and pin-autolock (`PasscodeState`
  mixes in `VerificationLockoutPolicy` from this feature) = 3 concrete consumers,
  feature-local to `auth/` exactly as this doc prescribes.
- [x] Composition root confined — **pass**: `attemptTrackerProvider` throws `StateError`;
  `InMemoryAttemptTracker` is constructed in both `AppDependencies.inMemory` and
  `.production` and overridden at the `ProviderScope` (app.dart:125).
- [x] Motion guarded — **pass** (warn resolved): login/OTP pages ship no countdown pulse or
  shake-on-locked — lockout UI is text-driven via `LockoutCountdownController`
  (ValueNotifier + 1s periodic Timer), so `disableAnimationsOf` has nothing to guard.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **pass**:
  `auth.login.attemptsRemaining(count)` / `lockedTitle` / `lockedBody(seconds)` /
  `tooManyAttempts` + matching `auth.otp.*` keys verified in all three locales (slang plural
  forms present).
- [x] Strict-analysis clean — **pass**: const schedule `[0, 0, 30, 60, 300, 900]` +
  `freeAttemptsBeforeLockout = 2`; typed `AttemptState` with non-negative asserts; no
  `dynamic`.
- [x] Generated code untouched — **pass**: `auth_attempt_tracker.freezed.dart` regenerated
  from source.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: pure Dart.
- [x] Goldens + dev-gallery fixture — **n/a** (per this doc): no canonical matrix case
  (countdown text is timing-sensitive); repo-wide re-baseline pending the pinned macOS 26 run
  (tracked repo-wide).
- [x] Port-reuse consistency — **pass**: one tracker consumed by three call sites; identifier
  keys are FNV-1a hashed (`hashIdentifier`), so raw email/phone PII never sits in the map
  (identifier-hygiene risk satisfied).
- [x] Config rule respected — **pass**: no env surface.
- [x] Honest feedback, no faked success — **pass** at runtime: a lockout either accepts or
  rejects; the submit button stays disabled while `lockedSeconds > 0`
  (login_page_test.dart:192, otp_page_test.dart:156) and `auth_attempt_tracker_test.dart`
  mirrors the const schedule exactly, clears on success, and returns `null` for unknown
  identifiers. The not-a-security-control dartdoc gap tracked in item 1 is closed, and the
  submit-disabled claim is asserted at `createApplication` level too
  (`integration_test/development_smoke_test.dart`).

## Risks / notes

- **Not a security control.** Client-side throttling is trivially bypassed (delete the prefs key, swap the device). Document this in the tracker's dartdoc and on the settings/diagnostics page; the real enforcement is server-side (e.g. the [mfa-otp](mfa-otp.md) test server returns `429 locked`). The two must agree on the cooldown schedule so the UI does not under-count.
- **Persistence choice is injected.** Default to in-memory (resets on relaunch — fine for UX). If persisted, use [`SecureStore`](../contracts.md#c4--port-reuse-do-not-multiply-backends) so a user cannot clear their lockout by clearing prefs; never `SettingsStore` (plaintext).
- **Identifier hygiene.** Keying by email/phone means a PII value sits in the tracker's memory/prefs — ensure the key itself is hashed (not the raw email) and that no `attempts` context reaches logs unredacted (verify against [log-redaction](log-redaction.md)).
- **Sequencing:** build before or alongside [mfa-otp](mfa-otp.md) and [pin-autolock](pin-autolock.md) — both consume `AttemptState` and would otherwise stub it and risk a circular dep.
