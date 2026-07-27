# License / share / in-app updates

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary
A bundle of three small platform-polish features that each touch the same native/settings seams:
Flutter's built-in `LicensePage` (legal/OSS attribution), a native share sheet (`share_plus`), and
in-app updates (Android Play in-app update / iOS App Store deep-link). All are backend-free and live
behind ports so the starter never depends on them to run. Bundled because they share the
diagnostics-page dev triggers and the `AppBuildInfo`/settings touchpoints.

## Contract
- **Ports / value objects:**
  - **License:** no port — `showLicensePage` reads Flutter's local license registry directly. Fed by
    [`AppBuildInfo`](../../lib/infrastructure/platform/app_build_info.dart) (version/buildNumber,
    already a dep) for `applicationVersion`; `applicationIcon` is omitted or supplied from a bundled
    asset (`AppBuildInfo` has no icon field).
  - **Share:** `ShareService` abstract interface — `shareText(String)`,
    `shareFiles(List<XFile>)` → `ShareResult`. Typed `ShareResult` (`success`, `unavailable`,
    `cancelled`). Mirrors the [`SettingsStore`](../../lib/features/settings/settings_store.dart) port
    discipline. `List<XFile>` matches `share_plus`'s native `shareXFiles` API, keeping the feature
    self-contained (no dependency on the unlanded `permissions-media` `PickedMedia` type).
  - **Updates:** `AppUpdateService` abstract interface — `checkForUpdate()` → `UpdateAvailability`
    (`noUpdate`, `available`, `required`), `performUpdate({bool immediate})`. Built from
    `AppBuildInfo` (version) + compile-time `AppConfig` (iOS Apple ID) for the iOS App Store URL.
- **Providers:** `shareServiceProvider` and `appUpdateServiceProvider` — handwritten
  `Provider<...>` overridden at the App `ProviderScope`.
- **Routes:** add `aboutLicense` / `/settings/about/license` (paired name+path; in-shell under the
  existing ShellRoute, or pushed from a settings "About" tile via `showLicensePage`). The update gate
  reuses the [update-blocker](./update-blocker.md) full-screen route / redirect when `required`; a
  soft update surfaces a dialog. Dev triggers live on `/dev/diagnostics`.
- **Files:**
  - `lib/features/settings/license_page.dart` — **add**; thin wrapper over `showLicensePage`.
  - `lib/infrastructure/sharing/share_service.dart` — **add**; port + `ShareResult`.
  - `lib/infrastructure/sharing/share_plus_share_service.dart` — **add**; prod (`share_plus`).
  - `lib/infrastructure/sharing/noop_share_service.dart` — **add**; hermetic — returns `unavailable`
    on platforms with no share target (web/desktop edge).
  - `lib/infrastructure/updates/app_update_service.dart` — **add**; port + `UpdateAvailability`.
  - `lib/infrastructure/updates/android_app_update_service.dart` — **add**; prod (`in_app_update`,
    Play).
  - `lib/infrastructure/updates/ios_app_update_service.dart` — **add**; prod (`url_launcher` → App
    Store URL from `AppBuildInfo` version + `AppConfig` iOS Apple ID).
  - `lib/app/config/app_config.dart` — **edit**; add `iosAppleId` field (read from `IOS_APPLE_ID`
    define).
  - `config/development.json` / `config/staging.json` / `config/production.json` — **edit**; add
    `IOS_APPLE_ID` (compile-time, not a secret).
  - `lib/infrastructure/updates/noop_app_update_service.dart` — **add**; hermetic — returns
    `noUpdate` (never fakes an available update).
  - `lib/app/routing/app_routes.dart` — **edit**; `aboutLicense`/`Path` constants.
  - `lib/app/routing/app_router.dart` — **edit**; GoRoute + rewire update gate.
  - `lib/features/settings/settings_page.dart` — **edit**; "About" tile → license page.
  - `lib/app/diagnostics/diagnostics_page.dart` — **edit**; dev triggers for share + update.
  - `lib/app/dependencies.dart` + `lib/app/app.dart` — **edit (root composition)**; overrides.
- **Dependencies:** `in_app_update`, `url_launcher` (new); `share_plus` is already transitive in
  `pubspec.lock` and `package_info_plus` is already a direct main dependency — verify version
  compatibility, do not re-add either.

## Backend & test surface
Backend-free. License = local Flutter registry. Share = OS sheet. Updates = OS store API (Android
Play / iOS App Store). No `tools/test_server/` contract. Production defaults: `SharePlusShareService`
+ platform `AppUpdateService`; goldens/integration override with the `Noop*` impls, which return
`unavailable` / `noUpdate` **honestly** and never fake a successful share or an available update. No
Mocktail — the noop impls are the fakes.

## Tests
- **Unit/widget:** license page builds with a `package_info_plus` fixture; `NoopShareService` returns
  `unavailable`; `NoopAppUpdateService` returns `noUpdate`; `UpdateAvailability`/`ShareResult`
  equality. Widget: settings "About" tile navigates to the license route.
- **Integration:** share trigger and update check via in-memory fakes (reuse `createApplication`;
  `pumpAppFrames`, never `pumpAndSettle`). Real `in_app_update` cannot run in CI (needs a Play Store
  device) — that path is noop-only in automated tests.
- **Golden impact:** add a `PreviewFrame` case for the license page (legal text); no full-matrix
  change.
- **Dev-gallery fixture:** share + update trigger fixtures under `developmentToolsEnabled` on
  `/dev/diagnostics`.

## i18n
- **Keys:** reuse existing `common.legalPlaceholderTitle`/`Body`; add `settings.about.license`,
  `share.unavailable`, `update.checkForUpdates`, `update.available`, `update.notAvailable`,
  `update.required`. Sync `en` + `ar` + `zh-Hans`, run `just gen`.
- **RTL note:** license legal text is LTR-dominant but `ar` copy must still translate the titles;
  the share sheet is OS-native (mirrors automatically).

## Audit
- [x] No-backend honored as a port — **pass**: two ports (`ShareService`, `AppUpdateService`), both
  backend-free; noop defaults surface `unavailable`/`noUpdate` honestly, never fake success.
- [x] Feature-first ownership; no `core/` `utils/` buckets — **warn (bundle discipline)**: license
  correctly in the settings feature; share/updates correctly under `lib/infrastructure/`; but three
  concerns share one doc — keep each concern's files scoped to its owner and do not let the bundle
  become a grab-bag.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**.
- [x] Motion guarded — **n/a**.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: exhaustive switches over `UpdateAvailability`/`ShareResult`.
- [ ] Native entitlements flagged in PR + CI platform jobs — **warn**: `in_app_update` is
  Android-only (Play Store); iOS uses `url_launcher` (no entitlement, but needs the App Store Apple
  ID in compile-time config — not a secret). Flag the Android release-build job.
- [x] Golden re-baseline noted on pinned macOS runner — **pass**: license page is a new PreviewFrame
  fixture; no full-matrix change.

## Risks / notes
- **`in_app_update` is untestable in CI** — it requires a real Android device with Play Services and
  a published Play listing. The noop default + a `/dev/diagnostics` manual trigger is the only
  automated coverage; document this limitation in the PR.
- **Do not duplicate the update gate.** [update-blocker](./update-blocker.md) (P2, server) is the
  server-min-version path; this feature is the OS-store path. Feed **one** gate (one redirect /
  full-screen route) from either source — never let both block independently, or users hit two
  walls. See [../contracts.md](../contracts.md) C5 (single redirect reused).
- **iOS App Store URL needs the Apple ID** — pass it via compile-time `AppConfig`
  (`--dart-define-from-file`), never hardcode and never treat as a secret.
- **`share_plus` is already transitive** — confirm the resolved version exposes the `shareXFiles`
  API the prod impl targets; do not re-declare a conflicting version.
- **Bundle is for sequencing only.** The three concerns can land in separate commits; the doc bundles
  them because they share the diagnostics dev triggers and the `AppBuildInfo`/settings seams.
  License is the lowest-risk and should land first.
