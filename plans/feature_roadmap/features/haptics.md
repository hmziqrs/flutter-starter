# Haptic feedback

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** done · **Depends on:** none

## Summary
Tactile feedback on key user actions (toggles, destructive confirms, pull-to-refresh, success/error
notifications) via the built-in `Haptic` API. Expected mobile polish — the codebase has **zero**
`HapticFeedback`/`Haptic.*` calls today. No backend, no plugin (flutter/services), but it must honor
the reduce-motion guardrail and a user opt-out.

## Contract
- **Ports / value objects:** `HapticService` abstract interface (port) with a typed `HapticKind` enum
  (`selection`, `impactLight`, `impactMedium`, `impactHeavy`, `notificationSuccess`,
  `notificationWarning`, `notificationError`) — exhaustive switch, no raw strings. Mirrors the
  [`SettingsStore`](../../lib/features/settings/settings_store.dart) port discipline (interface +
  prod impl under `lib/infrastructure/` + a noop test impl), even though there is no per-key store.
- **Providers:** `hapticServiceProvider` — handwritten `Provider<HapticService>` overridden at the App
  `ProviderScope` (peer of `settingsRepositoryProvider`). Persistence is the `hapticsEnabled` boolean
  on `SettingsState`, mutated only via `SettingsController.setHapticsEnabled`.
- **Routes:** none.
- **Files:**
  - `lib/infrastructure/haptics/haptic_service.dart` — **add**; port + `HapticKind` enum +
    `HapticServiceException` wrapper (consistent with `SettingsStoreException`).
  - `lib/infrastructure/haptics/device_haptic_service.dart` — **add**; prod impl wrapping
    `Haptic.*` from `flutter/services`.
  - `lib/infrastructure/haptics/noop_haptic_service.dart` — **add**; records calls, fires nothing —
    used for goldens/integration hermeticity.
  - `lib/features/settings/settings_state.dart` — **edit**; add `hapticsEnabled` field (default
    `true`) + include in `==`/`hashCode`/`copyWith`.
  - `lib/features/settings/settings_repository.dart` — **edit**; add `hapticsEnabledKey` to
    `persistedKeys`, load/save via the per-key store (no `clearAll`).
  - `lib/features/settings/settings_controller.dart` — **edit**; `setHapticsEnabled(bool)` with
    optimistic-update-with-rollback (matches existing setters).
  - `lib/features/settings/settings_page.dart` — **edit**; Appearance toggle bound to the setting.
  - `lib/app/dependencies.dart` — **edit (root composition)**; construct `DeviceHapticService`.
  - `lib/app/app.dart` — **edit (root composition)**; `ProviderScope` override for
    `hapticServiceProvider`.
- **Dependencies:** none (flutter/services `Haptic`). Do **not** pull `haptic_plus`/`feedback` unless
  the richer iOS `UIImpactFeedbackGenerator` intensity API is later required.

## Backend & test surface
Backend-free. Production default = `DeviceHapticService` (the real device). Tests/goldens override
with `NoopHapticService` for hermeticity — no `tools/hono_server/` contract, no Mocktail. The noop
does not surface "unavailable" feedback (haptics are fire-and-forget; there is no user-facing success
to fake).

## Tests
- **Unit/widget:** `NoopHapticService` records the last `HapticKind`; `DeviceHapticService` delegates
  one-to-one (cover the kind→`Haptic.*` mapping exhaustively). Widget: a button wired to the service
  does not fire when `hapticsEnabled == false` **or** when `MediaQuery.disableAnimationsOf(context)`
  is true.
- **Integration:** `createApplication` wires `hapticServiceProvider` (reuse the seam; `pumpAppFrames`).
- **Golden impact:** none (no visual change).
- **Dev-gallery fixture:** add a "Haptics" case under `developmentToolsEnabled` (`/dev/screens`) that
  triggers each `HapticKind` behind a `PreviewFrame`-isolated button row.

## i18n
- **Keys:** `settings.haptics.title`, `settings.haptics.enable` (+ dev-gallery label
  `devGallery.cases.haptics`). Sync across `en` + `ar` + `zh-Hans`, run `just gen`.
- **RTL note:** n/a.

## Audit

Implementation audit (2026-10-04) against the 13-item checklist in
[contracts.md](../contracts.md):

- [x] No-backend honored as a port — **pass**: port `HapticService` + `HapticKind` +
  `HapticServiceException` (`lib/infrastructure/haptics/haptic_service.dart`); production default
  is the real device adapter (`DeviceHapticService`, constructed in `dependencies.dart:406`);
  `NoopHapticService` is the hermetic test/golden default (`dependencies.dart:161`); backend-free,
  so no C2 server contract applies.
- [x] Feature-first ownership — **pass**: port trio under `lib/infrastructure/haptics/`; the
  `hapticsEnabled` field lives in the settings feature's own state/repository/controller
  (`settings_state.dart:93`, `settings_repository.dart:19,33`, `settings_controller.dart:56-58`)
  and the toggle in `settings/widgets/haptics_tile.dart` — no `core/`/`utils/`.
- [x] Shared extraction ≥3 consumers — **n/a**: no shared widget; the only trigger surface today
  is the dev-gallery case (`haptics_gallery_cases.dart:50-58`).
- [x] Composition root confined — **pass**: `hapticServiceProvider` throws unless overridden and
  is overridden only at the `ProviderScope` (`app.dart:126`) with adapters constructed only in
  `dependencies.dart`.
- [x] Motion guarded — **pass (load-bearing)**: the call site auto-suppresses on
  `MediaQuery.disableAnimationsOf(context)` **and** the `hapticsEnabled` user opt-out
  (`haptics_gallery_cases.dart:50-58`); both negative paths asserted in
  `test/infrastructure/haptics/haptic_call_site_test.dart:86-116`.
- [x] i18n synced en/ar/zh-Hans — **pass**: `settings.haptics.title`/`enable` +
  `devGallery.caseHaptic*`/`screenHaptics` verified present in all three
  `lib/i18n/*.i18n.json`.
- [x] Strict analysis clean — **pass**: exhaustive `HapticKind` switches in `DeviceHapticService`
  and the gallery labels; the kind→`HapticFeedback` mapping asserted exhaustively in
  `haptic_service_test.dart` (all 7 kinds against the platform channel).
- [x] Generated code untouched — **n/a**: no generated code in this feature.
- [x] Native entitlements flagged — **n/a**: `HapticFeedback` needs no entitlement.
- [x] Goldens re-baselined + dev-gallery fixture — **n/a/pass**: no visual change (doc: no golden
  impact); the Haptics trigger case exists behind `developmentToolsEnabled`
  (`haptics_gallery_cases.dart`, registered `gallery_registry.dart:43`).
- [x] Port-reuse consistency — **pass**: settings persistence rides the existing per-key
  `SettingsStore` (`appearance.haptics_enabled`); no second settings surface.
- [x] Config rule respected — **pass**: no config surface; gallery gated by
  `developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: fire-and-forget contract, nothing faked; the
  settings tile surfaces `common.notConnected` and rolls back on persistence failure
  (`settings_tile_save_failure_test.dart:22-64`).

## Risks / notes
- **Reduce-motion coupling is mandatory.** Firing haptics while `disableAnimationsOf` is true is
  inconsistent UX — gate at the call site, not centrally, so each consumer stays auditable. See the
  motion guardrail in [`lib/shared/motion/`](../../lib/shared/motion/).
- **iOS Taptic Engine vs Android vibrator** differ in amplitude/quality; the enum intentionally maps
  to the SDK's cross-platform surface — do not promise parity.
- **Define a small canonical trigger set** (toggle, destructive confirm, pull-to-refresh,
  success/error notification). Resist ad-hoc sprinkling; a starter's value is the *consistent*
  contract, not blanket buzzing.
- **Sequencing:** independent; extend `SettingsState` in the same pass as
  [a11y-presets](./a11y-presets.md) to avoid repeated churn to
  `persistedKeys`/`settings_repository.dart`.
- Pairs with the future [pull-refresh](./pull-refresh.md) and [toast-dialogs](./toast-dialogs.md)
  features as canonical haptic triggers.
