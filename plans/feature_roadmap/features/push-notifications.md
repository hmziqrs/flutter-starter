# Push notifications

> **Tier:** P2 · **Domain:** engagement · **Backend:** test-server · **Status:** planned · **Depends on:** settings

## Summary

Remote (FCM/APNs) and local scheduled notifications for re-engagement and account events —
the primary mobile retention channel and a default user expectation on iOS/Android. The
starter ships the full port + a Noop default so it runs green with zero backend; the real
Firebase wiring is an opt-in override a consumer constructs only after adding credentials.

## Contract

- **Ports / value objects:** `NotificationsRepository` abstract interface (request permission,
  register token stream, subscribe/unsubscribe topic, schedule local, cancel) mirroring the
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) per-key discipline (no
  batch wipe, exceptions wrapped). Typed `NotificationPermissionStatus` enum
  (`denied`/`notRequested`/`provisional`/`granted`); `NotificationTap` value object
  (`targetRoute` name + typed `Map<String,String>` params) consumed by the router. Token and
  permission status persist via `SettingsStore` under one JSON key each.
- **Providers:** handwritten Riverpod only — `notificationsRepositoryProvider` (overridden at
  the [`ProviderScope`](../../../lib/app/app.dart)), `notificationsControllerProvider` (Notifier
  exposing `permission`/`token`/`registrationState`), `notificationTapQueueProvider`
  (cold-start + foreground taps buffered until the router is mounted). Follow the
  [`SettingsController`](../../../lib/features/settings/settings_controller.dart) Notifier shape;
  **no** `riverpod_generator`.
- **Routes:** no new `AppRoutes` constant required for the surface itself — taps resolve to
  **existing** named routes via `context.pushNamed` using helpers like
  [`AppRoutes.otpLocation`](../../../lib/app/routing/app_routes.dart). A dev-only deep-link
  trigger may live under `/dev/*` behind `if (config.developmentToolsEnabled)`.
- **Files:** feature-first —
  - `lib/features/notifications/notification_tap.dart`
  - `lib/features/notifications/notification_permission_status.dart`
  - `lib/features/notifications/notifications_repository.dart` (port)
  - `lib/features/notifications/noop_notifications_repository.dart` (production default)
  - `lib/features/notifications/notifications_controller.dart`
  - `lib/infrastructure/notifications/firebase_notifications_repository.dart` (opt-in real impl)
  - **root-composition edits (flagged):** [`lib/bootstrap.dart`](../../../lib/bootstrap.dart)
    (plugin init inside `createApplication` **after**
    [`WidgetsFlutterBinding.ensureInitialized()`](../../../lib/bootstrap.dart) — already called
    at lines 17 and 35), [`lib/app/dependencies.dart`](../../../lib/app/dependencies.dart)
    (`AppDependencies.production` constructs the Noop default; the Firebase impl is constructed
    only when a consumer passes credentials via an `AppDependencies` parameter),
    [`lib/app/app.dart`](../../../lib/app/app.dart) (`ProviderScope` override + foreground-tap
    wiring in `_AppViewState`).
- **Dependencies:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications`. All
  three are opt-in — added to `pubspec.yaml` only when a consumer wires the real impl; the Noop
  default keeps the dependency tree backend-free.

## Backend & test surface

Per [D2](../decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
the starter runs green with **zero backend**, surfaces `common.notConnected` honestly, and never
fakes success.

- **Noop production default** — `NoopNotificationsRepository` returns
  `NotificationPermissionStatus.denied` and an empty token stream; the controller surfaces
  `context.t.common.notConnected` for any subscribe/schedule action and records the unavailable
  state. `AppDependencies.production` constructs this; no `firebase_*` dependency is pulled.
- **Optional real override** — `FirebaseNotificationsRepository` wraps `firebase_messaging` +
  `flutter_local_notifications`; a consumer constructs it (with platform credentials) and
  overrides `notificationsRepositoryProvider`. It is never constructed by default.
- **Test-server contract** — FCM/APNs cannot be meaningfully mocked by a plain HTTP server (see
  [D3](../decisions.md#d3--minimal-in-repo-test-server-tools-test_server) known limitation). The
  [`tools/test_server/`](../decisions.md#d3--minimal-in-repo-test-server-tools-test_server)
  Dart server therefore implements **only the token-registration/permission path**:
  - `POST /v1/notifications/register-token` `{token, platform, deviceId}` -> `204` (idempotent store)
  - `DELETE /v1/notifications/register-token/{token}` -> `204`
  - `POST /v1/notifications/permission-revoked` `{deviceId}` -> `204`
  Integration tests start the server on a random port and point a thin
  `HttpNotificationsRegistrationClient` (real impl, constructed only in the test/dev graph) at
  it; the foreground-message rendering path is covered by `flutter_local_notifications` + a fake
  messaging repository (in-memory, no Mocktail).
- **Fakes** — `InMemoryNotificationsRepository` (fake messaging stream + controllable permission)
  for widget/controller tests, mirroring
  [`InMemorySettingsStore`](../../../lib/features/settings/in_memory_settings_store.dart).

## Tests

- **Unit/widget:** `notifications_controller_test.dart` — permission state machine, tap queue
  ordering, cold-start tap replayed after router mount, Noop surfaces `notConnected` and never
  reports a granted token. Value-object equality on `NotificationTap`.
- **Integration:** reuse `createApplication`; drive the registration client against the
  `tools/test_server` with `pumpAppFrames` (8 bounded frames), **never** `pumpAndSettle`.
  Verify a foreground tap issues `context.pushNamed` to the existing route, not a raw URI.
- **Golden impact:** none — no persistent UI surface (the foreground banner is transient and
  rendered by the OS). A dev-gallery fixture renders the in-app permission rationale only.
- **Dev-gallery fixture:** one `TypedGalleryCase` behind `developmentToolsEnabled` previewing
  the permission rationale + denied/granted states via
  [`PreviewFrame`](../../../lib/features/dev_gallery/preview_frame.dart); registered through
  [`production_gallery_cases.dart`](../../../lib/features/dev_gallery/cases/production_gallery_cases.dart).

## i18n

- **Keys:** `notifications.enableTitle`, `notifications.enableBody`, `notifications.deny`,
  `notifications.allow`, `notifications.enableBlockedTitle`, `notifications.enableBlockedBody`
  (open-settings CTA), `notifications.disabled` (the honest unavailable surface). Sync across
  `en` + `ar` + `zh-Hans`, then `just gen`.
- **RTL note:** rationale sheet is text-only and direction-neutral; no direction-sensitive
  glyphs.

## Audit

- [x] **pass** — No-backend honored as a port: `NoopNotificationsRepository` is the prod default,
  surfaces `notConnected`, never grants a token.
- [x] **pass** — Feature-first ownership: port + controller + value objects under
  `lib/features/notifications/`; only the optional Firebase adapter lives in `lib/infrastructure/`.
- [ ] **warn** — No shared widget is extracted (rationale sheet stays feature-local); confirm at
  review that it is not promoted to `lib/shared/widgets/` without ≥3 consumers.
- [x] **pass** — Motion guarded: the rationale sheet has no custom animation; the OS notification
  UI is out of scope.
- [x] **pass** — Tests use `pumpAppFrames`, never `pumpAndSettle`.
- [x] **pass** — i18n synced en/ar/zh-Hans; `gen-check` stays clean.
- [x] **pass** — Strict-analysis clean: typed enums, exhaustive switches on permission status,
  no `dynamic`.
- [ ] **warn** — Native entitlements flagged in PR + CI: APNs entitlement (iOS
  `aps-environment`), Firebase config files (`GoogleService-Info.plist` /
  `google-services.json`), Android `POST_NOTIFICATIONS` runtime permission. The CI platform
  jobs must build with these present when the real impl is exercised.
- [x] **n/a-pass** — Golden re-baseline: no persistent UI; none required.

## Risks / notes

- **Native config is outside `lib/`.** Push is the most entitlement-heavy feature in the roadmap
  — iOS capability + APNs entitlement, Android `POST_NOTIFICATIONS` (API 33+) runtime prompt,
  and per-platform Firebase config files. These live in `ios/`/`android/` and must be called out
  in the PR and covered by the platform build jobs in
  [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml).
- **Plugin init order is load-bearing.** Initialize messaging **inside** `createApplication`
  after `WidgetsFlutterBinding.ensureInitialized()` (bootstrap.dart:17,35) and **before** the
  router is built, so the cold-start tap is captured into `notificationTapQueueProvider` before
  `_AppViewState` subscribes — otherwise the first tap is lost.
- **Token persistence.** Research pins token + permission to `SettingsStore`; an FCM token is a
  delivery address, not a credential, so [`SecureStore`](secure-store.md) is not required. If a
  consumer later treats the device identity as sensitive, route it through the shared
  [`SecureStore`](secure-store.md) port instead — do not introduce a second secrets adapter.
- **Logs auto-redact.** Token/permission flows go through
  [`AppLogger`](../../../lib/infrastructure/logging/app_logger.dart) with structured context;
  never pre-redact — the [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) scrubs tokens by pattern.
- **Web/desktop skipped** via [`PlatformCapabilities`](../../../lib/infrastructure/platform/platform_capabilities.dart):
  select the Noop default whenever `platform` is **not** `ios` or `android` (`firebase_messaging`
  has no desktop/web support). `isWeb`/`supportsFileSystem` alone are insufficient —
  `supportsFileSystem = !isWeb` is true on every native platform and cannot distinguish desktop
  from mobile.
- **Not a backend for other features.** Unlike [`ConnectivityService`](connectivity.md) or the
  remote-config family, the notifications port has a single reader; do not generalize it into a
  messaging bus.
