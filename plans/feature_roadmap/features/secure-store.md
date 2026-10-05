# SecureStore port

> **Tier:** P0 · **Domain:** security · **Backend:** none · **Status:** done · **Depends on:** none

## Summary

OS-backed encrypted per-key store (Keychain / Keystore / DPAPI / libsecret) for tokens,
refresh tokens, PIN/biometric hashes, and any future secret. `SharedPreferences` is plaintext,
so this is the foundational primitive every security feature in the roadmap builds on. Ship it
first — it is the lowest-friction, highest-leverage add because it unblocks
[`session`](session.md), [`biometric`](biometric.md), [`pin-autolock`](pin-autolock.md), and
the analytics opt-in key.

## Contract

- **Ports / value objects:** `SecureStore` abstract interface mirroring
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) exactly — `read`,
  `write`, `delete` per key, all `Future`-returning and throwing `SecureStoreException`. **No
  `clearAll`** (matches the SettingsStore discipline; the repo forbids bulk wipes). Each call
  wraps the underlying plugin in `try/on Object -> SecureStoreException`.
- **Providers:** `secureStoreProvider` handwritten Riverpod `Provider<SecureStore>`, overridden
  at the `ProviderScope` in [`lib/app/app.dart`](../../../lib/app/app.dart) as a peer of
  `settingsRepositoryProvider`. Constructed in
  [`AppDependencies.production`](../../../lib/app/dependencies.dart) alongside the settings
  repo. Throws `StateError` if read unoverridden (same shape as `settingsRepositoryProvider`).
- **Routes:** none (pure infrastructure).
- **Files:**
  - `lib/infrastructure/secure_storage/secure_store.dart` (port + `SecureStoreException`)
  - `lib/infrastructure/secure_storage/flutter_secure_storage_store.dart` (sole prod impl)
  - `lib/features/security/in_memory_secure_store.dart` (test fake with `failReads`/`failWrites`
    toggles, mirroring [`InMemorySettingsStore`](../../../lib/features/settings/in_memory_settings_store.dart))
  - **EDIT** `lib/app/dependencies.dart` — construct + expose on `AppDependencies`
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - `test/infrastructure/secure_storage/secure_store_test.dart`
  - `test/features/security/in_memory_secure_store_test.dart`
  - `pubspec.yaml` — add `flutter_secure_storage`
- **Dependencies:** `flutter_secure_storage` (the only package). Pure Flutter SDK on the port
  itself.

## Backend & test surface

**Backend-free.** The default production impl (`FlutterSecureStorageStore`) is real and local —
it writes to the OS keychain/keystore, not a server. There is no Noop default and no fake of
success: every operation either returns the stored value (or `null`) or throws
`SecureStoreException`. The `InMemorySecureStore` is a **test fake only**, never constructed in
production code paths (the
[honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)).

Configure platform options once in the prod impl: `AndroidOptions(encryptedSharedPreferences:
true)`, `IOSOptions(accessibility: KeychainAccessibility.first_unlock)`, and the macOS
`useDataProtectionKeychain` flag. Web/desktop fall back to the plugin's supported backend or
throw `SecureStoreException` on unsupported platforms (do not silently fall through to
`SharedPreferences`).

## Tests

- **Unit/widget:** `secure_store_test.dart` exercises round-trip read/write/delete +
  `SecureStoreException` wrapping (use the in-memory fake; do not hit the real keychain in unit
  tests). `in_memory_secure_store_test.dart` verifies `failReads`/`failWrites` toggles.
- **Integration:** no direct integration test — the port has no UI. Downstream features
  ([`session`](session.md), [`biometric`](biometric.md)) integration tests reuse
  `createApplication` + `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`.
- **Golden impact:** none.
- **Dev-gallery fixture:** n/a (no UI). Surface a row on
  [`DiagnosticsPage`](../../../lib/app/diagnostics/diagnostics_page.dart) showing the backend
  kind (Keychain/Keystore/etc.) read-only, gated by `developmentToolsEnabled`.

## i18n

- **Keys:** none (no user-facing strings).
- **RTL note:** n/a.

## Audit

- [x] **No-backend honored as a port** — pass: port at `lib/infrastructure/secure_storage/secure_store.dart`
  (per-key `read`/`write`/`delete`, `SecureStoreException`, no `clearAll`); prod impl
  `flutter_secure_storage_store.dart` wraps every op via `guardStorageOpAsync`; the
  `InMemorySecureStore` fake is constructed only in `AppDependencies.inMemory` — never in
  `.production` (dependencies.dart:227 uses `FlutterSecureStorageStore()`).
- [x] **Feature-first ownership; no core/ utils/ buckets** — pass: port under
  `lib/infrastructure/secure_storage/`, fake under `lib/features/security/`, no buckets.
- [x] **shared/widgets extraction only if >=3 consumers** — n/a: no widget; the port itself is
  the C4 secrets seam.
- [x] **Composition root confined** — pass: `secureStoreProvider`
  (secure_store_provider.dart) throws `StateError`; overridden once at the `ProviderScope`
  (app.dart:89) from `AppDependencies.storage`.
- [x] **Motion guarded** — n/a: no animation; downstream integration tests use
  `pumpAppFrames` (integration_test/development_smoke_test.dart).
- [x] **i18n synced en/ar/zh-Hans; gen-check stays clean** — n/a: no strings; the
  DiagnosticsPage row renders `resolveSecureStoreBackend().name` (diagnostics_page.dart:115)
  from the `SecureStoreBackend` enum, not localized copy.
- [x] **Strict-analysis clean** — pass: typed `SecureStoreException` extends
  `OperationException`; no `dynamic`/raw types in the audited files.
- [x] **Generated code untouched** — pass: no codegen in this area.
- [x] **Native entitlements flagged in PR + CI platform jobs** — pass (warn resolved):
  `keychain-access-groups` landed in both `macos/Runner/DebugProfile.entitlements:13` and
  `Release.entitlements:9`. The original Android `encryptedSharedPreferences` warn is obsolete:
  `flutter_secure_storage` is pinned at ^11.2.0, which **removed** that parameter (v10+ uses the
  keystore-backed custom cipher by default — see the plugin CHANGELOG), so no Gradle
  scratch-space config is needed. CI builds macOS/iOS on `macos-26`
  (.github/workflows/release.yml); Android via `just build apk`.
- [x] **Goldens re-baselined + dev-gallery fixture** — n/a: no visual change; the
  DiagnosticsPage backend row replaces the gallery fixture per this doc. Repo-wide golden
  re-baseline is outstanding (the committed baselines are outdated vs HEAD) (tracked repo-wide).
- [x] **Port-reuse consistency** — pass: single `SecureStore` consumed by session
  (`session.refresh_token`), passcode (`security.passcode.*` keys), and the analytics opt-in
  (dependencies.dart:228); no parallel secrets port exists under `lib/`.
- [x] **Config rule respected** — pass: no runtime env reads; the diagnostics row is read-only.
- [x] **Honest feedback, no faked success** — pass: every op returns the stored value (or
  `null`) or throws `SecureStoreException`; the fail-toggle fake is test-only
  (in_memory_secure_store_test.dart verifies the toggles throw).

## Risks / notes

- **Port-reuse owner ([C4](../contracts.md#c4--port-reuse-do-not-multiply-backends)):** this is
  the **single** secrets adapter for the whole roadmap. Refresh tokens, PIN/biometric hashes,
  analytics opt-in, and any future secret all flow through `secureStoreProvider` — do not spin
  up a parallel secure store per feature.
- **Native config is the real risk.** macOS/iOS need the Keychain Sharing entitlement
  (`*.entitlements`); Android needs the `encryptedSharedPreferences` Gradle setup. If the
  consumer forgets the entitlement, reads silently return `null` on macOS — surface this on
  `DiagnosticsPage` and in the PR description. Track under
  [`docs/release_readiness.md`](../../../docs/release_readiness.md).
- **No `clearAll`.** A "wipe everything" flow (logout, factory reset) iterates the known key
  set and calls `delete` per key. Hardcoding the key catalog in one place keeps the discipline.
- **Sequencing:** build this **before** any other security feature. The
  [`session`](session.md) refresh-token persistence, [`biometric`](biometric.md) enable-flag,
  and [`pin-autolock`](pin-autolock.md) PIN hash all block on `secureStoreProvider` existing.
