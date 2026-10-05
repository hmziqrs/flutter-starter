# Push notifications

> **Tier:** P2 · **Domain:** engagement · **Backend:** test-server · **Status:** done · **Depends on:** settings
>
> Implementation-audit gaps (2026-10-04) — closed 2026-10-05: SettingsStore persistence is wired
> (`persistedPermissionKey`/`persistedTokenKey` seed on build, persist on change); the router drain
> (`app.dart:246-270`) is driven to `pushNamed` by
> `test/features/notifications/notification_tap_dispatch_test.dart`; the foreground rendering path
> (`_renderForeground` via `flutter_local_notifications`) is exercised by
> `test/infrastructure/notifications/firebase_notifications_repository_test.dart`.

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
  three are declared in `pubspec.yaml` (compiled into every build — the starter does not keep
  them out of the dependency tree). The opt-in boundary is at runtime, not at dependency level:
  `AppDependencies.production` constructs the Noop default, and the Firebase impl is only ever
  constructed when a consumer passes credentials, so no `firebase_*` plugin is initialized in the
  default graph.

## Backend & test surface

Per [C2](../contracts.md#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
the starter runs green with **zero backend**, surfaces `common.notConnected` honestly, and never
fakes success.

- **Noop production default** — `NoopNotificationsRepository` returns
  `NotificationPermissionStatus.denied` and an empty token stream; the controller surfaces
  `context.t.common.notConnected` for any subscribe/schedule action and records the unavailable
  state. `AppDependencies.production` constructs this, so no `firebase_*` plugin is ever
  initialized in the default graph.
- **Optional real override** — `FirebaseNotificationsRepository` wraps `firebase_messaging` +
  `flutter_local_notifications`; a consumer constructs it (with platform credentials) and
  overrides `notificationsRepositoryProvider`. It is never constructed by default.
- **Test-server contract** — FCM/APNs cannot be meaningfully mocked by a plain HTTP server (see
  [C3](../contracts.md#c3--minimal-in-repo-test-server) known limitation). The
  [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server)
  Hono server therefore implements **only the token-registration/permission path**:
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
  reports a granted token, SettingsStore persistence round-trips. Value-object equality on
  `NotificationTap`. The tap-to-`pushNamed` drain is covered by
  `notification_tap_dispatch_test.dart`; foreground rendering by
  `firebase_notifications_repository_test.dart` (recording plugin fake).
- **Integration:** what landed is client-level plus widget-level, not an app-level `createApplication`
  flow against the server. `test/e2e/hono_server_e2e_test.dart:103` drives the real
  `HttpNotificationsRegistrationClient` against the running `tools/hono_server` (live server on a
  random port) and round-trips register-token / unregister-token / permission-revoked; the
  tap-to-`context.pushNamed` dispatch (to the existing named route, not a raw URI) is covered at
  widget level by `test/features/notifications/notification_tap_dispatch_test.dart` using
  `pumpAppFrames` (bounded frames, **never** `pumpAndSettle`).
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

Implementation audit (2026-10-04) against the 13-item checklist in
[contracts.md](../contracts.md):

- [x] No-backend honored as a port — **pass**: all four C2 parts exist — port
  (`notifications_repository.dart`), honest Noop production default
  (`dependencies.dart:444-449`; Noop returns `denied` + throws `notConnected`, verified by
  `notifications_controller_test.dart:16-35`), opt-in `FirebaseNotificationsRepository` (never
  constructed in the default graph), and the test-server contract (`POST/DELETE
  /v1/notifications/register-token`, `POST /v1/notifications/permission-revoked` at
  `hono_server/src/index.ts:393-421`, contract-tested `hono_server/test/contract.test.ts:432-456`,
  driven e2e `test/e2e/hono_server_e2e_test.dart:103`). The declared test surface is complete:
  foreground rendering via a recording plugin fake and a tap driven through the app-level drain
  to `pushNamed`.
- [x] Feature-first ownership — **pass**: port + controller + value objects + Noop + InMemory fake
  under `lib/features/notifications/`; only the optional Firebase/HTTP adapters live in
  `lib/infrastructure/notifications/`.
- [x] Shared extraction ≥3 consumers — **pass**: the rationale preview stays feature-local (inside
  `notifications_gallery_cases.dart`); nothing promoted to `lib/shared/widgets/`.
- [x] Composition root confined — **pass**: repository + backend + initial permission/token
  overridden only at the `ProviderScope` (`app.dart:138-147`), constructed only in
  `AppDependencies` (`dependencies.dart:149-154,444-449`); widgets never touch a plugin.
- [x] Motion guarded — **pass**: the rationale surface is static text; the OS notification UI is
  out of scope; no custom animation added.
- [x] i18n synced en/ar/zh-Hans — **pass**: `notifications.*` (enableTitle/Body, allow, deny,
  enableBlockedTitle/Body, disabled) verified present in all three `lib/i18n/*.i18n.json`.
- [x] Strict analysis clean — **pass**: exhaustive switches over permission status
  (`FirebaseNotificationsRepository._mapAuthorizationStatus`,
  `NotificationsController._landFromException` at `notifications_controller.dart:186-192`);
  typed `NotificationTap`/`NotificationMessage` Freezed values.
- [x] Generated code untouched — **pass**: `notification_tap.freezed.dart` +
  `notifications_controller.freezed.dart` committed alongside their `part` sources.
- [x] Native entitlements flagged — **pass**: landed — `aps-environment` in
  `ios/Runner/Runner.entitlements` (development) + `ios/Runner/Release.entitlements`
  (production), `POST_NOTIFICATIONS` in `android/app/src/main/AndroidManifest.xml`, both with
  comments documenting the consumer-supplied `GoogleService-Info.plist`/`google-services.json`
  step.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: no persistent UI (doc: no golden
  impact); rationale + notRequested/granted/denied preview fixture exists
  (`notifications_gallery_cases.dart`, registered `gallery_registry.dart:47`).
- [x] Port-reuse consistency — **pass**: single-reader port per this doc; no parallel secrets or
  connectivity port introduced (token deliberately stays out of `SecureStore`).
- [x] Config rule respected — **pass**: no runtime env switching; the Noop default is the
  production graph; gallery behind `developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the Noop never fakes (unavailable + denied
  asserted in `notifications_controller_test.dart:16-35`), and the Contract's SettingsStore
  persistence claim is implemented: `persistedPermissionKey`/`persistedTokenKey`
  (`notifications_controller.dart`) seed the controller on build and persist on every
  permission/token change (covered by the `SettingsStore persistence` test group).

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
