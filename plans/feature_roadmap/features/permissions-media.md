# Runtime permissions + media picker

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** in-progress · **Depends on:** none
>
> Implementation-audit gaps (2026-10-04): the granted→pick→`onAvatarPicked(media)` happy path has
> no test (only the dismiss path is covered, and the claimed `createApplication` integration test
> with a fixture-returning fake picker does not exist); the `/dev/diagnostics` dev trigger from the
> file list never landed; and `profile_routes.dart:62-70` ignores a successfully picked image
> (null shows `avatarUnavailable`, non-null is a silent no-op).

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
    `location`); `PermissionStatus` value (`granted`, `denied`,
    `permanentlyDenied`, `restricted`). Exhaustive switches, no raw ints. The OS notification-permission
    request is owned by [push-notifications](./push-notifications.md)
    (`NotificationsRepository.requestPermission` + `NotificationPermissionStatus`); this feature does
    not declare a `notifications` kind.
  - `MediaPicker` abstract interface — `pickImage({bool fromCamera})` → `PickedMedia?` (typed:
    path + mimeType) or `null` when cancelled. Mirrors the [`SettingsStore`](../../lib/features/settings/settings_store.dart)
    discipline: interface + prod impl under `lib/infrastructure/` + a hermetic noop impl.
- **Providers:** `permissionServiceProvider` and `mediaPickerProvider` — handwritten
  `Provider<...>` overridden at the App `ProviderScope` (peer of `settingsRepositoryProvider`).
- **Routes:** none new. The rationale + denied UI is a reusable sheet. The avatar path at
  [`app_router.dart:231`](../../lib/app/routing/app_router.dart) (`onAvatarFeedback` →
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
  - `lib/features/profile/widgets/permission_rationale_sheet.dart` — **add**; ForUI `FSheet` wrapped in
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
image — the no-faked-success rule is load-bearing here. No `tools/hono_server/` contract. No Mocktail;
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
- **Keys:** `permission.<camera|photos|location>.title` + `.rationale`,
  `permission.openSettings`, `permission.denied`, `permission.permanentlyDenied`. Sync `en` + `ar` +
  `zh-Hans`, run `just gen`.
- **RTL note:** direction-sensitive — the rationale sheet's leading icon and action buttons mirror
  under `ar`; verify with the RTL PreviewFrame case.

## Audit

Implementation audit (2026-10-04) against the 13-item checklist in
[contracts.md](../contracts.md):

- [x] No-backend honored as a port — **warn**: both ports exist (`PermissionService` +
  `MediaPicker`, `lib/infrastructure/{permissions,media}/`); noop hermetic defaults surface
  denied/null honestly (`noop_permission_service_test.dart:9-24`,
  `noop_media_picker_test.dart:9-19`); rationale always precedes the OS prompt
  (`update_profile_page.dart:633-662`). The warn is the untested happy path: no test drives
  granted→pick→`onAvatarPicked(PickedMedia)` (only the dismiss path is covered,
  `update_profile_page_test.dart:20-38`), the claimed `createApplication` integration test with a
  fixture-returning fake picker does not exist, and `profile_routes.dart:62-70` silently ignores a
  successfully picked image.
- [x] Feature-first ownership — **pass**: ports + device/noop adapters under
  `lib/infrastructure/{permissions,media}/`; rationale sheet + avatar flow owned by the profile
  feature (`profile/widgets/permission_rationale_sheet.dart`, `update_profile_page.dart`); no
  `core/`/`utils/`.
- [x] Shared extraction ≥3 consumers — **pass**: the sheet stayed feature-local under
  `lib/features/profile/widgets/` exactly as this doc pins (only profile/avatar consumes it
  today); nothing promoted to `lib/shared/widgets/`.
- [x] Composition root confined — **pass**: both providers throw unless overridden and are
  overridden only at the `ProviderScope` (`app.dart:141-142`); platform selection (device on
  ios/android, Noop elsewhere incl. web) lives only in `AppDependencies.production`
  (`dependencies.dart:429-449`); plugins imported only by infrastructure adapters.
- [x] Motion guarded — **pass**: the sheet uses ForUI's built-in `FSheet` via
  `showAppBottomSheet` wrapped in `EscapeDismissibleOverlay` (`app_bottom_sheet.dart:19`); no
  custom entrance was added, so no additional guard is needed (the doc's warn was conditional).
- [x] i18n synced en/ar/zh-Hans — **pass**: `permission.{camera,photos,location}.title/rationale`
  + `continueRequest`/`openSettings`/`denied`/`permanentlyDenied`/`notNow` verified present in all
  three `lib/i18n/*.i18n.json`; RTL rendering tested
  (`permission_rationale_sheet_test.dart:98-118`).
- [x] Strict analysis clean — **pass**: sealed `PermissionStatus` hierarchy + exhaustive switches
  over `AppPermission` (`permission_service.dart:52-58`,
  `noop_permission_service_test.dart:63`); typed `PickedMedia` with value equality
  (`noop_media_picker_test.dart:29-55`).
- [x] Generated code untouched — **n/a**: no generated code in this feature.
- [x] Native entitlements flagged — **pass**: landed — `NSCameraUsageDescription`,
  `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription` in
  `ios/Runner/Info.plist:14-18`; `CAMERA`/`READ_MEDIA_IMAGES`/`ACCESS_COARSE_LOCATION` in
  `android/app/src/main/AndroidManifest.xml` with rationale-first comments (notifications stay
  owned by push-notifications, incl. `POST_NOTIFICATIONS`).
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: rationale sheet + denied/
  permanently-denied gallery cases exist (`permissions_gallery_cases.dart`, registered
  `gallery_registry.dart:48`); no full-matrix change — repo-wide re-baseline still pending the
  pinned macOS 26 CI run (tracked repo-wide).
- [x] Port-reuse consistency — **pass**: no `notifications` kind declared (OS notification
  permission stays owned by push-notifications, as this doc requires); `MediaPicker` is the single
  pick port for future share/feedback flows.
- [x] Config rule respected — **pass**: no config surface; gallery behind
  `developmentToolsEnabled`. The planned `/dev/diagnostics` trigger never landed (gap noted in
  the header) — the dev gallery is the preview surface.
- [x] Honest feedback, no faked success — **pass**: noop picker returns null → route surfaces
  `profile.update.avatarUnavailable` (`profile_routes.dart:62-70`); noop permission service never
  fakes a grant (tested); permanently-denied offers open-settings, not a re-prompt
  (`permission_rationale_sheet_test.dart:34-52,77-96`).

## Risks / notes
- **Permanently-denied is a one-way door.** Once the user picks "Don't ask again", re-prompting is a
  no-op — the rationale sheet must route to `openSystemSettings()` (`app_settings`), not back to
  `requestStatus`. This is the single most common implementation bug.
- **Native entitlements ship per-platform.** Camera/photos/location require iOS
  `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` /
  `NSLocationWhenInUseUsageDescription` strings in `Info.plist` and Android `<uses-permission>` entries
  (e.g. `CAMERA`, `READ_MEDIA_IMAGES`, `ACCESS_COARSE_LOCATION`) in `AndroidManifest.xml`, plus the
  API-33+ `POST_NOTIFICATIONS` runtime prompt on Android (owned by push-notifications). Flag these in
  the PR and cover them in the iOS / Android / macOS release-build CI jobs (checklist §9); a missing
  usage string crashes the runtime prompt on first request.
- **Rationale before prompt, always.** Never request a permission cold (e.g. on screen open) — show
  the rationale sheet first; stores reject apps that request without context.
- **Callback signature change is breaking.** `onAvatarFeedback: VoidCallback` →
  `onAvatarPicked(PickedMedia?)` on `UpdateProfilePage`/`_AvatarEditor`; update
  [`app_router.dart`](../../lib/app/routing/app_router.dart) and the feature-contract doc together
  (see [contracts.md](../contracts.md)).
- **Notification permission is owned by [push-notifications](./push-notifications.md)** — it is the
  canonical owner of the OS notification-permission request (`NotificationsRepository.requestPermission`
  + `NotificationPermissionStatus`); this feature does not request notification permission or declare a
  `notifications` kind. See push-notifications.md for the bidirectional reference.
- **`MediaPicker` generalizes** beyond the avatar: future share-result and feedback-screenshot flows
  reuse it — that is why it is a port, not an inline `image_picker` call.
- No `clearAll` analog; permission state is not persisted in `SettingsStore` (the OS owns it). Do not
  add a "permission granted" cache that can drift from the OS.
