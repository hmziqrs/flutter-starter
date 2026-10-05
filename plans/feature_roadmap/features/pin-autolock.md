# PIN / passcode + session auto-lock

> **Tier:** P3 · **Domain:** security · **Backend:** none · **Status:** done · **Depends on:** secure-store, biometric

## Summary

A user-set local numeric/alphanumeric passcode that gates app entry as a fallback to (or substitute for) biometrics, **combined** with idle/background auto-lock so the app re-challenges for identity after a configurable period or on background→foreground. The two ship together because PIN is what makes auto-lock meaningful on devices where Face/Touch ID is absent or disabled — banking and enterprise apps ship both by default.

## Contract

- **Ports / value objects:** reuses [`SecureStore`](../../../lib/infrastructure/secure_storage/) for storing only a **salted hash** of the PIN (never the raw value). New typed values under `lib/features/security/`:
  - `PasscodeState` (`enabled`, `attemptsRemaining`, `lockedUntil`, `isSet`) with a derived `bool get requiresChallenge => isSet && enabled && lockedUntil == null` (the predicate the redirect reads below).
  - `AutoLockState` (`locked`, `lockedReason` ∈ {`idleTimeout`, `backgroundReturn`, `manual`}).
  - `PasscodeHasher` pure-Dart interface (`saltAndHash(String pin, String salt)`) — sole prod impl wraps `package:crypto`; never store or log the cleartext.
  - Reuses the [auth-ratelimit](auth-ratelimit.md) `AttemptTracker` for the max-attempt lockout counter.
- **Providers:** handwritten Riverpod — `passcodeControllerProvider` (Notifier over `PasscodeState`, methods `setPasscode`/`changePasscode`/`disable`/`verify`), `autoLockControllerProvider` (Notifier over `AutoLockState`, methods `arm`/`unlock`/`extend`). No codegen. Both overridden at the App [`ProviderScope`](../../../lib/app/app.dart) through [`AppDependencies`](../../../lib/app/dependencies.dart).
- **Routes:** paired constants in [`AppRoutes`](../../../lib/app/routing/app_routes.dart) — `passcodeEntry = 'passcode-entry'`, `passcodeEntryPath = '/passcode'`; `passcodeSetup = 'passcode-setup'`, `passcodeSetupPath = '/settings/security/passcode'`. Both top-level (full-screen). The **same `go_router` redirect** used by [biometric](biometric.md) consumes `AutoLockState.locked || PasscodeState.requiresChallenge` to push `/passcode` (with the biometric route tried first per the policy).
- **Files:**
  - add `lib/features/security/passcode_controller.dart`
  - add `lib/features/security/passcode_page.dart` (entry + setup surfaces, on `AuthPageScaffold` + `EscapeDismissibleOverlay`)
  - add `lib/features/security/passcode_hasher.dart`
  - add `lib/features/security/auto_lock_controller.dart`
  - (no separate `WidgetsBindingObserver` — the idle `Timer` lives in `auto_lock_controller.dart` above; the background→foreground re-lock event comes from ref.watch `appLifecyclePhaseProvider`, owned by [lifecycle-observer](lifecycle-observer.md), avoiding a second binding observer)
  - **edit** `lib/features/settings/settings_state.dart` (`passcodeEnabled`, `autoLockDelaySeconds`, `lockOnBackground` fields)
  - **edit** `lib/features/settings/settings_repository.dart` (`persistedKeys` + load/save)
  - **edit** `lib/features/settings/settings_controller.dart` (setters)
  - **edit** `lib/features/settings/settings_page.dart` (security section: auto-lock delay picker, background-lock toggle)
  - **edit** `lib/app/routing/app_routes.dart` + `lib/app/routing/app_router.dart` (routes + redirect) — **root composition**
  - (no bootstrap observer registration — lifecycle events arrive via `appLifecyclePhaseProvider`; only the controller providers are wired in `dependencies.dart`/`app.dart` below)
  - **edit** `lib/app/dependencies.dart` + `lib/app/app.dart` (wire overrides) — **root composition**
  - add `test/features/security/passcode_controller_test.dart`, `test/features/security/auto_lock_controller_test.dart`, `test/features/security/passcode_hasher_test.dart`
- **Dependencies:** `crypto` (pub). No biometric dep (that's the sibling feature).

## Backend & test surface

**Backend-free.** All hashing, verification, and idle timing are local. The default impl is real (`CryptoPasscodeHasher` + `SecureStore`-backed repository), not a stub. `AutoLockController` owns the wall-clock idle `Timer` and `ref.watch`es `appLifecyclePhaseProvider` (owned by [lifecycle-observer](lifecycle-observer.md)) for the background→foreground re-lock — it does **not** register its own `WidgetsBindingObserver` (single-observer model). No backend, no plugin. No test-server contract; **never** surface `common.notConnected` for an unlock attempt (that would be a fake-success smell — a local gate either accepts or rejects).

## Tests

- **Unit/widget:** `passcode_hasher_test.dart` proves salt is unique per call, hash is deterministic for `(pin, salt)`, and cleartext never appears in output. `passcode_controller_test.dart` drives set → verify → max-attempt lockout → disable using an in-memory `SecureStore` fake (no Mocktail). `auto_lock_controller_test.dart` uses `FakeAsync` to advance the idle timer past `autoLockDelaySeconds` and asserts `AutoLockState.locked` flips; asserts a `resumed` lifecycle event with `lockOnBackground=true` arms the lock.
- **Integration:** reuse `createApplication`; `pumpAppFrames`, **never** `pumpAndSettle`. Pump the lifecycle via `TestWidgetsFlutterBinding.handleAppLifecycleStateChanged`.
- **Golden impact:** none for entry screen (dev-gallery only). A canonical matrix case is **not** added — passcode dots + cursor are timing-sensitive and would force re-baselines for no signal.
- **Dev-gallery fixture:** `PreviewFrame` cases — `passcode-entry` (idle / error / locked-out), `passcode-setup` (confirm-mismatch) — in `production_gallery_cases.dart`, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** new `security.passcode.*` group — `enterTitle`, `enterBody`, `setupTitle`, `setupBody`, `confirmTitle`, `reenter`, `mismatch`, `incorrect(attempts:)`, `lockedOut(seconds:)`, `disable`, `settings.passcode`, `settings.autoLockDelay`, `settings.lockOnBackground`. Add `security.autoLock.*` if copy diverges. Sync across `en.i18n.json`, `ar.i18n.json`, `zh-Hans.i18n.json`; run `just gen`.
- **RTL note:** PIN dots are LTR-numeric; titles/body follow `Directionality`. Pluralization for `attempts` must use slang's plural form (`(attempts:)` param).

## Audit

- [x] No-backend honored as a port — **pass**: fully local; `verify` returns
  success/incorrect/lockedOut/notConfigured — never `common.notConnected` (would be a
  fake-success smell).
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: hasher/controllers/pages under
  `lib/features/security/`; idle `Timer` lives in `auto_lock_controller.dart`; no second
  `WidgetsBindingObserver` anywhere in the feature.
- [x] Shared/widgets extraction only if ≥3 consumers — **n/a**: reuses `AuthPageScaffold` +
  `EscapeDismissibleOverlay`; no new shared widget.
- [x] Composition root confined — **pass**: `passcodeControllerProvider` /
  `autoLockControllerProvider` handwritten Notifiers; `autoLockDelaySecondsProvider` /
  `lockOnBackgroundProvider` overridden from live settings at the `ProviderScope`
  (app.dart:154-159); `passcodeHasherProvider` holds only a pure-Dart impl with an injectable
  secure-random factory.
- [x] Motion guarded — **pass** (warn resolved): the shake fallback still sets the error +
  attempts copy when `disableAnimationsOf` (passcode_page.dart:375-385); `_Dot` pulse (line
  434) and `_ShakeGuard` (line 475) return static children first; all tweens use `AppMotion`.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **pass**: `security.passcode.*`
  incl. plural `incorrect(attempts)` / `lockedOut(seconds)` verified in all three locales; PIN
  dots pinned `TextDirection.ltr` (passcode_page.dart:402).
- [x] Strict-analysis clean — **pass**: exhaustive switches over `PasscodeVerifyResult` /
  `AutoLockReason`; constant-time hash compare; no `dynamic`.
- [x] Generated code untouched — **pass**: `passcode_controller.freezed.dart` /
  `auto_lock_controller.freezed.dart` are regenerations matching their source models (git diff
  corresponds 1:1 to source field changes).
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: `crypto` is pure Dart;
  lifecycle arrives via the SDK-only `appLifecyclePhaseProvider`.
- [x] Goldens + dev-gallery fixture — **pass**: no canonical matrix case (per this doc);
  `pin_autolock_gallery_cases.dart` ships `passcode.entry.idle` / `entry.error` /
  `entry.lockedOut` / `setup.mismatch`; repo-wide re-baseline pending the pinned macOS 26 run
  (tracked repo-wide).
- [x] Port-reuse consistency — **pass**: salt/hash/attempts persisted via the single
  `SecureStore` (five `security.passcode.*` keys — tamper-resistant per the risk note);
  lockout reuses the auth-ratelimit schedule through `VerificationLockoutPolicy` +
  `computeLockout`/`cooldownSecondsFor`/`freeAttemptsBeforeLockout`
  (verification_lockout_policy.dart) rather than re-implementing it; the challenge gate chains
  through the one `appRedirect` (route_guards.dart:67-69) — `AutoLockController.arm()` arms the
  passcode challenge that redirect reads, so idle/background lockouts land on `/passcode` via
  the same seam.
- [x] Config rule respected — **pass**: no env reads; delay/background flags are user
  settings persisted via `SettingsStore`.
- [x] Honest feedback, no faked success — **pass**: `verify` never fakes success; cleartext
  never persisted or logged (`passcode_hasher_test.dart`: 'cleartext pin never appears in the
  salt or hash output'; controller logs carry no `pin=` context).

## Risks / notes

- **Hash, never encrypt-and-store.** `passcode_hasher.dart` stores only `salt + sha256(salt||pin)`; if a future "forgot PIN" path is added it must **wipe** the salt/hash (forcing re-setup), not recover the cleartext. Cross-check against [log-redaction](log-redaction.md) so no `pin=` assignment leaks via logs (the existing `_sensitiveAssignment` regex already covers `passcode=`, but verify the new context keys).
- **Redirect composition:** this is the **fourth** reader of the [C5 redirect helper](../contracts.md#c5--one-go_router-redirect-pattern-reused). Lock precedence must be defined exactly once — recommended order: `update-blocker` (hard block) → `onboarding-gate` → `session` (auth) → `auto-lock` (re-challenge) → `biometric` (prompt) → `passcode` (fallback). Document the order in `app_router.dart`.
- **Reuses the single observer owned by [lifecycle-observer](lifecycle-observer.md).** Do **not** register a second `WidgetsBindingObserver`; `AutoLockController` `ref.watch`es `appLifecyclePhaseProvider` for background→foreground events and runs its own wall-clock idle `Timer`. (The earlier standalone `AutoLockObserver` design was dropped to avoid double-registration.)
- **Idle timer + reduce-motion:** the timer is wall-clock, not animation-driven, so `disableAnimationsOf` does not pause it — but any countdown UI must still respect the motion guard.
- **Brute-force lockout reuses `AttemptTracker`** from [auth-ratelimit](auth-ratelimit.md); do not re-implement. Persist `attemptsRemaining` + `lockedUntil` via `SecureStore` (not `SettingsStore`) so it is tamper-resistant.
