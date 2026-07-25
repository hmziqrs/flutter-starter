# Biometric unlock

> **Tier:** P1 · **Domain:** security · **Backend:** none · **Status:** planned · **Depends on:** secure-store

## Summary

On-device fingerprint / Face ID / device-credential authentication used to gate app entry or sensitive actions via the OS biometric hardware. Table-stakes for any fork handling PII, finance, or health, and one of the most commonly expected features in a forked starter — convenience plus defense-in-depth.

## Contract

- **Ports / value objects:** `BiometricAuthenticator` abstract interface in `lib/infrastructure/biometric/` mirroring the [`SettingsStore`](../../../lib/features/settings/settings_store.dart) / [`PlatformCapabilities`](../../../lib/infrastructure/platform/platform_capabilities.dart) port pattern — methods `Future<BiometricAvailability> checkAvailability()` and `Future<bool> authenticate({required String localizedReason})`. Typed `BiometricAvailability` value object (`canCheck`, `supportedBiometrics`, `requiresSetup`, reason). No `clearAll`-style bulk calls — single-purpose surface. A `BiometricLockState` sealed value (`unlocked` / `locked` / `unavailable`) is the controller's public state.
- **Providers:** handwritten Riverpod `biometricUnlockControllerProvider` (Notifier) over `BiometricLockState`, plus a `biometricAuthenticatorProvider` overridden at the App [`ProviderScope`](../../../lib/app/app.dart) through [`AppDependencies`](../../../lib/app/dependencies.dart) — exactly the `settingsRepositoryProvider` shape. Tests override with a stub authenticator (no Mocktail).
- **Routes:** paired constants in [`AppRoutes`](../../../lib/app/routing/app_routes.dart) — `biometricLock = 'biometric-lock'`, `biometricLockPath = '/lock'`. Top-level route (full-screen, like auth), **not** inside the `ShellRoute`. A `go_router` **redirect** in [`buildAppRouter`](../../../lib/app/routing/app_router.dart) consumes `BiometricLockState.locked` to send protected routes to `AppRoutes.biometricLockPath`. This redirect is the second user of the [D5 redirect helper](../decisions.md#d5--one-go_router-redirect-pattern-reused) — reuse it, do not invent a per-feature redirect.
- **Files:**
  - add `lib/infrastructure/biometric/biometric_authenticator.dart` (port + `BiometricAvailability` / `BiometricLockState`)
  - add `lib/infrastructure/biometric/local_auth_authenticator.dart` (sole prod impl)
  - add `lib/infrastructure/biometric/noop_biometric_authenticator.dart` (web/unsupported default — returns `canCheck: false`)
  - add `lib/features/security/biometric_unlock_controller.dart`
  - add `lib/features/security/biometric_lock_page.dart` (consumer of `AuthPageScaffold` + `EscapeDismissibleOverlay`)
  - **edit** `lib/features/settings/settings_state.dart` (add `biometricUnlockEnabled` field)
  - **edit** `lib/features/settings/settings_repository.dart` (add `persistedKeys` entry + load/save)
  - **edit** `lib/features/settings/settings_controller.dart` (add setter)
  - **edit** `lib/features/settings/settings_page.dart` (render toggle)
  - **edit** `lib/app/routing/app_routes.dart` + `lib/app/routing/app_router.dart` (lock route + redirect) — **root composition**
  - **edit** `lib/app/dependencies.dart` + `lib/app/app.dart` (wire provider override) — **root composition**
  - add `test/features/security/biometric_unlock_controller_test.dart`, `test/infrastructure/biometric/noop_biometric_authenticator_test.dart`
- **Dependencies:** `local_auth` (pub). Tests reuse `InMemorySecureStore` from [secure-store](secure-store.md) (no extra fake).

## Backend & test surface

**Backend-free.** All work is local against the OS biometric API; the default impl (`LocalAuthAuthenticator`) is real, not a stub. The `NoopBiometricAuthenticator` is the deterministic default for web / desktop-unsupported / integration-test runs so the starter stays green and goldens stay stable — it reports `canCheck: false` honestly (does **not** fake a successful unlock). No test-server contract, no optional real impl, no `common.notConnected` path.

## Tests

- **Unit/widget:** `biometric_unlock_controller_test.dart` drives unlocked/locked/unavailable transitions via a stub authenticator and asserts the redirect predicate. `noop_biometric_authenticator_test.dart` proves web/unsupported returns `canCheck: false`. Widget test renders `BiometricLockPage` in the dev-gallery harness (`auth_test_harness.dart`-style localized app) and asserts the unlock button + copy.
- **Integration:** reuse `createApplication`; `pumpAppFrames` (8 bounded), **never** `pumpAndSettle`. Integration tests must inject `NoopBiometricAuthenticator` via override so they never trigger the platform plugin.
- **Golden impact:** none — lock screen is dev-gallery only; no canonical matrix case (would risk platform-biometric-prompt nondeterminism).
- **Dev-gallery fixture:** `PreviewFrame` case in `lib/features/dev_gallery/cases/production_gallery_cases.dart` rendering the lock page in `locked` / `unavailable` states, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** new `security.biometric.*` group — `lockTitle`, `lockBody`, `unlock`, `unlocking`, `unavailableTitle`, `unavailableBody`, `useFallback` (PIN handoff), `settings.enableBiometric`. Add to `lib/i18n/en.i18n.json`, `ar.i18n.json`, `zh-Hans.i18n.json` in sync; run `just gen`.
- **RTL note:** body copy is direction-agnostic; the unlock icon button stays leading-edge via `Directionality`-aware padding.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free; Noop default reports unavailable honestly, never fakes success.
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: port under `lib/infrastructure/biometric/`, UI under `lib/features/security/`.
- [x] Shared/widgets extraction only if ≥3 consumers — **n/a**: reuses existing `EscapeDismissibleOverlay` (already shared); no new shared widget.
- [x] Motion guarded — **warn**: lock-page entry animation and the success → unlock transition must be guarded by `MediaQuery.disableAnimationsOf(context)` with a `jumpTo`-style fallback; implementer must not skip this.
- [x] Tests use `pumpAppFrames`, never `pumpAndSettle` — **pass**.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: typed `BiometricAvailability`, exhaustive `BiometricLockState` switch, no `dynamic`.
- [x] Native entitlements flagged in PR + CI platform jobs — **warn**: requires `NSFaceIDUsageDescription` (iOS), `USE_BIOMETRIC` permission (Android), Windows Hello capability; must land in `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`, and be exercised in the platform CI jobs.
- [x] Golden re-baseline noted — **n/a**: no canonical matrix case.

## Risks / notes

- **Sequencing:** the `biometricUnlockEnabled` flag is persisted via `SettingsStore` (plaintext) — fine for a boolean toggle, but if the toggle itself must be tamper-resistant route it through `SecureStore` ([D4](../decisions.md#d4--port-reuse-do-not-multiply-backends)) instead. Decide before freezing the contract.
- **Redirect reuse:** this is the **third** reader of the [D5 redirect helper](../decisions.md#d5--one-go_router-redirect-pattern-reused) (after update-blocker + session). Coordinate the redirect predicate merge order so it composes (`locked` short-circuits before session check).
- **Platform divergence:** `local_auth` throws on desktop without Keychain setup; `NoopBiometricAuthenticator` is the safety net keyed off `PlatformCapabilities`, not a try/catch at call sites.
- **Pairs with [pin-autolock](pin-autolock.md):** when biometric is unavailable the lock page falls through to the PIN entry screen; build the handoff seam even if PIN ships later.
