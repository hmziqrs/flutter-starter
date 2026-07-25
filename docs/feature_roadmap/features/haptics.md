# Haptic feedback

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** planned · **Depends on:** none

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
with `NoopHapticService` for hermeticity — no `tools/test_server/` contract, no Mocktail. The noop
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
- [x] No-backend honored as a port — **pass**: port + real device default; noop is for hermeticity
  only (backend=none, so the real impl is local — this is the correct shape, not the D2 four-part
  contract which applies to `server` features).
- [x] Feature-first ownership; no `core/` `utils/` buckets — **pass**: port under
  `lib/infrastructure/haptics/`; the `SettingsState` edit is expected cross-cutting via the settings
  feature's own `persistedKeys`.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**: no shared widget.
- [x] Motion guarded — **pass (load-bearing)**: every call site must auto-suppress when
  `MediaQuery.disableAnimationsOf(context)` is true — reduce-motion parity. This is the single most
  important guard for this feature.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: exhaustive switch over `HapticKind`, typed provider.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: `Haptic` needs no entitlement.
- [x] Golden re-baseline noted on pinned macOS runner — **n/a**.

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
  [system-ui](./system-ui.md) and [a11y-presets](./a11y-presets.md) to avoid repeated churn to
  `persistedKeys`/`settings_repository.dart`.
- Pairs with the future [pull-refresh](./pull-refresh.md) and [toast-dialogs](./toast-dialogs.md)
  features as canonical haptic triggers.
