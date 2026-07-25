# Runtime permissions + media picker

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary
Request device permissions (camera, photos, notifications, location) with a pre-prompt rationale and
a path to system settings when permanently denied, and promote the avatar "unavailable" stub to a real
media picker. Stores reject apps that request without context, and users silently-permanently deny
permissions that lack a rationale step. Backend-free — but every protected resource flows through a
port so goldens/integration stay hermetic.

## Contract
- **Ports / value objects:**
  - `PermissionService` abstract interface — `requestStatus(AppPermission)`,
    `checkStatus(AppPermission)`, `openSystemSettings()`. `AppPermission` enum (`camera`, `photos`,
    `notifications`, `location`); `PermissionStatus` value (`granted`, `denied`,
    `permanentlyDenied`, `restricted`). Exhaustive switches, no raw ints.
  - `MediaPicker` abstract interface — `pickImage({bool fromCamera})` → `PickedMedia?` (typed:
    path + mimeType) or `null` when cancelled. Mirrors the [`SettingsStore`](../../lib/features/settings/settings_store.dart)
    discipline: interface + prod impl under `lib/infrastructure/` + a hermetic noop impl.
- **Providers:** `permissionServiceProvider` and `mediaPickerProvider` — handwritten
  `Provider<...>` overridden at the App `ProviderScope` (peer of `settingsRepositoryProvider`).
- **Routes:** none new. The rationale + denied UI is a reusable sheet. The avatar path at
  [`app_router.dart:217`](../../lib/app/routing/app_router.dart) (`onAvatarFeedback` →
  `_showInformationDialog(...avatarUnavailable)`) is rewired to invoke the picker flow; the callback
  signature on `UpdateProfilePage`/`_AvatarEditor` changes from `VoidCallback` to a typed
  `onAvatarPicked(PickedMedia?)`.
- **Files:**
  - `lib/infrastructure/permissions/permission_service.dart` — **add**; port + enums + value.
  - `lib/infrastructure/permissions/device_permission_service.dart` — **add**; prod
    (`permission_handler`).
  - `lib/infrastructure/permissions/noop_permission_service.dart` — **add**; hermetic — returns
    `denied`/`permanentlyDenied` (honest, never fakes a grant).
  - `lib/infrastructure/media/media_picker.dart` — **add**; port + `PickedMedia`.
  - `lib/infrastructure/media/image_picker_media_picker.dart` — **add**; prod (`image_picker`).
  - `lib/infrastructure/media/noop_media_picker.dart` — **add**; hermetic — returns `null`
    (cancelled/unavailable), surfacing `profile.update.avatarUnavailable`.
  - `lib/shared/widgets/permission_rationale_sheet.dart` — **add**; ForUI `FSheet` wrapped in
    [`EscapeDismissibleOverlay`](../../lib/shared/widgets/escape_dismissible_overlay.dart).
  - `lib/features/profile/update_profile_page.dart` — **edit**; consume `PickedMedia?`.
  - `lib/app/routing/app_router.dart` — **edit**; rewire `onAvatarFeedback` → picker.
  - `lib/app/diagnostics/diagnostics_page.dart` — **edit**; dev trigger (gated by
    `developmentToolsEnabled`).
  - `lib/app/dependencies.dart` + `lib/app/app.dart` — **edit (root composition)**; overrides.
- **Dependencies:** `permission_handler`, `app_settings`, `image_picker` (none currently in
  `pubspec.lock`).

## Backend & test surface
Backend-free. Production default = `Device*` impls (real hardware). Goldens/integration override with
the `Noop*` impls, which return **denied / unavailable** honestly and never fake a grant or a picked
image — the no-faked-success rule is load-bearing here. No `tools/test_server/` contract. No Mocktail;
the noop impls ARE the fakes.

## Tests
- **Unit/widget:** `NoopPermissionService` returns the documented denied states; `PickedMedia`
  equality; rationale sheet renders title/rationale/open-settings; permanently-denied path offers
  "open settings" (not a re-prompt). Widget: avatar editor surfaces `avatarUnavailable` when the noop
  picker returns `null`.
- **Integration:** avatar picker flow end-to-end with an in-memory fake picker returning a fixture
  `PickedMedia` (reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`).
- **Golden impact:** add a `PreviewFrame` case for the rationale sheet (does not perturb the full
  canonical matrix).
- **Dev-gallery fixture:** rationale sheet + denied/permanently-denied states under
  `developmentToolsEnabled`.

## i18n
- **Keys:** `permission.<camera|photos|notifications|location>.title` + `.rationale`,
  `permission.openSettings`, `permission.denied`, `permission.permanentlyDenied`. Sync `en` + `ar` +
  `zh-Hans`, run `just gen`.
- **RTL note:** direction-sensitive — the rationale sheet's leading icon and action buttons mirror
  under `ar`; verify with the RTL PreviewFrame case.

## Audit
- [x] No-backend honored as a port — **pass**: two ports; noop hermetic defaults surface
  denied/unavailable honestly and never fake a grant or picked image.
- [x] Feature-first ownership; no `core/` `utils/` buckets — **pass**: ports under
  `lib/infrastructure/{permissions,media}/`; profile feature consumes; shared sheet qualifies (below).
- [x] shared/widgets extraction only if >=3 consumers — **pass**: `permission_rationale_sheet` serves
  ≥4 permission kinds (camera/photos/notifications/location) — meets the threshold.
- [x] Motion guarded — **warn**: `FSheet` slide is ForUI-built-in; if any custom entrance is added,
  guard with `MediaQuery.disableAnimationsOf` + a non-animated fallback that still opens the sheet.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: exhaustive switch over `AppPermission`/`PermissionStatus`.
- [ ] Native entitlements flagged in PR + CI platform jobs — **warn**: camera/photo/notifications/
  location need iOS `NSXxxUsageDescription` strings + Android runtime permissions in
  `AndroidManifest.xml`; flag in PR, cover in platform release-build jobs.
- [x] Golden re-baseline noted on pinned macOS runner — **pass**: rationale sheet is a new
  `PreviewFrame` fixture; no full-matrix change.

## Risks / notes
- **Permanently-denied is a one-way door.** Once the user picks "Don't ask again", re-prompting is a
  no-op — the rationale sheet must route to `openSystemSettings()` (`app_settings`), not back to
  `requestStatus`. This is the single most common implementation bug.
- **Rationale before prompt, always.** Never request a permission cold (e.g. on screen open) — show
  the rationale sheet first; stores reject apps that request without context.
- **Callback signature change is breaking.** `onAvatarFeedback: VoidCallback` →
  `onAvatarPicked(PickedMedia?)` on `UpdateProfilePage`/`_AvatarEditor`; update
  [`app_router.dart`](../../lib/app/routing/app_router.dart) and the feature-contract doc together
  (see [`plans/feature_contracts.md`](../../plans/feature_contracts.md)).
- **Notification permission couples with [push-notifications](./push-notifications.md)** — sequence
  after it, or gate the `notifications` kind behind that feature landing. Do not request notification
  permission from this feature in isolation.
- **`MediaPicker` generalizes** beyond the avatar: future share-result and feedback-screenshot flows
  reuse it — that is why it is a port, not an inline `image_picker` call.
- No `clearAll` analog; permission state is not persisted in `SettingsStore` (the OS owns it). Do not
  add a "permission granted" cache that can drift from the OS.
