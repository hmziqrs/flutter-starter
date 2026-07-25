# PIN / passcode + session auto-lock

> **Tier:** P3 · **Domain:** security · **Backend:** none · **Status:** planned · **Depends on:** secure-store, biometric

## Summary

A user-set local numeric/alphanumeric passcode that gates app entry as a fallback to (or substitute for) biometrics, **combined** with idle/background auto-lock so the app re-challenges for identity after a configurable period or on background→foreground. The two ship together because PIN is what makes auto-lock meaningful on devices where Face/Touch ID is absent or disabled — banking and enterprise apps ship both by default.

## Contract

- **Ports / value objects:** reuses [`SecureStore`](../../../lib/infrastructure/secure_storage/) for storing only a **salted hash** of the PIN (never the raw value). New typed values under `lib/features/security/`:
  - `PasscodeState` (`enabled`, `attemptsRemaining`, `lockedUntil`, `isSet`).
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
  - add `lib/app/auto_lock_observer.dart` (`WidgetsBindingObserver` + idle `Timer`) — **root composition adjacent**
  - **edit** `lib/features/settings/settings_state.dart` (`passcodeEnabled`, `autoLockDelaySeconds`, `lockOnBackground` fields)
  - **edit** `lib/features/settings/settings_repository.dart` (`persistedKeys` + load/save)
  - **edit** `lib/features/settings/settings_controller.dart` (setters)
  - **edit** `lib/features/settings/settings_page.dart` (security section: auto-lock delay picker, background-lock toggle)
  - **edit** `lib/app/routing/app_routes.dart` + `lib/app/routing/app_router.dart` (routes + redirect) — **root composition**
  - **edit** `lib/bootstrap.dart` (register `AutoLockObserver` in `createApplication`) — **root composition**
  - **edit** `lib/app/dependencies.dart` + `lib/app/app.dart` (wire overrides) — **root composition**
  - add `test/features/security/passcode_controller_test.dart`, `test/features/security/auto_lock_controller_test.dart`, `test/features/security/passcode_hasher_test.dart`
- **Dependencies:** `crypto` (pub). No biometric dep (that's the sibling feature).

## Backend & test surface

**Backend-free.** All hashing, verification, idle timing, and lifecycle observation are local. The default impl is real (`CryptoPasscodeHasher` + `SecureStore`-backed repository), not a stub. `AutoLockController` reads `WidgetsBindingObserver.didChangeAppLifecycleState` directly — no backend, no plugin. No test-server contract; **never** surface `common.notConnected` for an unlock attempt (that would be a fake-success smell — a local gate either accepts or rejects).

## Tests

- **Unit/widget:** `passcode_hasher_test.dart` proves salt is unique per call, hash is deterministic for `(pin, salt)`, and cleartext never appears in output. `passcode_controller_test.dart` drives set → verify → max-attempt lockout → disable using an in-memory `SecureStore` fake (no Mocktail). `auto_lock_controller_test.dart` uses `FakeAsync` to advance the idle timer past `autoLockDelaySeconds` and asserts `AutoLockState.locked` flips; asserts a `resumed` lifecycle event with `lockOnBackground=true` arms the lock.
- **Integration:** reuse `createApplication`; `pumpAppFrames`, **never** `pumpAndSettle`. Pump the lifecycle via `TestWidgetsFlutterBinding.handleAppLifecycleStateChanged`.
- **Golden impact:** none for entry screen (dev-gallery only). A canonical matrix case is **not** added — passcode dots + cursor are timing-sensitive and would force re-baselines for no signal.
- **Dev-gallery fixture:** `PreviewFrame` cases — `passcode-entry` (idle / error / locked-out), `passcode-setup` (confirm-mismatch) — in `production_gallery_cases.dart`, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** new `security.passcode.*` group — `enterTitle`, `enterBody`, `setupTitle`, `setupBody`, `confirmTitle`, `reenter`, `mismatch`, `incorrect(attempts:)`, `lockedOut(seconds:)`, `disable`, `settings.passcode`, `settings.autoLockDelay`, `settings.lockOnBackground`. Add `security.autoLock.*` if copy diverges. Sync across `en.i18n.json`, `ar.i18n.json`, `zh-Hans.i18n.json`; run `just gen`.
- **RTL note:** PIN dots are LTR-numeric; titles/body follow `Directionality`. Pluralization for `attempts` must use slang's plural form (`(attempts:)` param).

## Audit

- [x] No-backend honored as a port — **pass**: fully local; no `common.notConnected` path for unlock (would be a fake-success smell).
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: all under `lib/features/security/` + the observer under `lib/app/` (composition-root adjacent, mirroring how `AppShell` lives there).
- [x] Shared/widgets extraction only if ≥3 consumers — **n/a**: reuses `AuthPageScaffold` + `EscapeDismissibleOverlay`; no new shared widget.
- [x] Motion guarded — **warn**: the shake-on-incorrect micro-interaction and the locked-out countdown pulse must be guarded by `MediaQuery.disableAnimationsOf(context)` with a non-animated fallback that still updates the attempt counter.
- [x] Tests use `pumpAppFrames`, never `pumpAndSettle` — **pass**.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: exhaustive switches over `AutoLockState.lockedReason` / `PasscodeState`; no `dynamic`, no raw types.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: no native permission needed (`crypto` is pure Dart; lifecycle observer is SDK-only).
- [x] Golden re-baseline noted — **n/a**.

## Risks / notes

- **Hash, never encrypt-and-store.** `passcode_hasher.dart` stores only `salt + sha256(salt||pin)`; if a future "forgot PIN" path is added it must **wipe** the salt/hash (forcing re-setup), not recover the cleartext. Cross-check against [log-redaction](log-redaction.md) so no `pin=` assignment leaks via logs (the existing `_sensitiveAssignment` regex already covers `passcode=`, but verify the new context keys).
- **Redirect composition:** this is the **fourth** reader of the [D5 redirect helper](../decisions.md#d5--one-go_router-redirect-pattern-reused). Lock precedence must be defined exactly once — recommended order: `update-blocker` (hard block) → `onboarding-gate` → `session` (auth) → `auto-lock` (re-challenge) → `biometric` (prompt) → `passcode` (fallback). Document the order in `app_router.dart`.
- **`AutoLockObserver` is a `WidgetsBindingObserver`** — there must be exactly one registered; coordinate with any future lifecycle-observer feature to avoid double-registration (see [lifecycle-observer](lifecycle-observer.md), the P0 host that this feature plugs into rather than replacing).
- **Idle timer + reduce-motion:** the timer is wall-clock, not animation-driven, so `disableAnimationsOf` does not pause it — but any countdown UI must still respect the motion guard.
- **Brute-force lockout reuses `AttemptTracker`** from [auth-ratelimit](auth-ratelimit.md); do not re-implement. Persist `attemptsRemaining` + `lockedUntil` via `SecureStore` (not `SettingsStore`) so it is tamper-resistant.
