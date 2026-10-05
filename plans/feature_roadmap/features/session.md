# Session / token management

> **Tier:** P1 · **Domain:** security · **Backend:** test-server · **Status:** done · **Depends on:** secure-store, lifecycle-observer

## Summary

One authoritative `AuthSession` (access token in memory, refresh token in
[`SecureStore`](secure-store.md)) that route guards, network clients, and the UI all read.
Installs an auth-required `go_router` redirect that **reuses** the pattern established by
[`update-blocker`](update-blocker.md) / [`onboarding-gate`](onboarding-gate.md) per
[C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) — the same shared helper is later
consumed by [`biometric`](biometric.md) and [`pin-autolock`](pin-autolock.md).

## Contract

- **Ports / value objects:**
  - `AuthSession` immutable value object (`accessToken`, `refreshToken` only in memory,
    `expiresAt`, `userId`). Modeled on
    [`SettingsState`](../../../lib/features/settings/settings_state.dart).
  - `AuthRepository` abstract port — `login(...)`, `refresh(...)`, `logout()`, all
    `Future<AuthSession>`-returning and throwing `AuthException`. **No production impl**
    (the no-backend rule).
  - `SessionRepository` thin wrapper over [`SecureStore`](secure-store.md) for the refresh
    token only (per-key `read`/`write`/`delete`, no `clearAll`).
- **Providers:**
  - `sessionControllerProvider` — handwritten Riverpod `Notifier<AuthSession>` (no codegen),
    modeled on [`SettingsController`](../../../lib/features/settings/settings_controller.dart).
    Optimistic update with rollback on `AuthRepository` failure.
  - `authRepositoryProvider` — `Provider<AuthRepository>` throwing `StateError` if unoverridden
    (same shape as `settingsRepositoryProvider`); default is the in-memory fake.
- **Routes:** no new routes — reuses
  [`AppRoutes.login`](../../../lib/app/routing/app_routes.dart). Adds a `go_router` `redirect`
  in [`buildAppRouter`](../../../lib/app/routing/app_router.dart) sending authenticated-only
  destinations to `AppRoutes.loginPath` when `AuthSession` is anonymous. **Reuse the
  [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) redirect helper** — the first
  redirect is established by [`update-blocker`](update-blocker.md) or
  [`onboarding-gate`](onboarding-gate.md) per the [sequencing](../README.md#sequencing); session
  consumes the shared helper here and does **not** introduce a new one.
- **Files:**
  - `lib/features/session/auth_session.dart` (value object + enums)
  - `lib/features/session/session_controller.dart`
  - `lib/features/session/session_repository.dart` (SecureStore-backed)
  - `lib/features/session/auth_repository.dart` (port + `AuthException`)
  - `lib/features/session/in_memory_auth_repository.dart` (default fake, surfaces
    `common.notConnected`)
  - `lib/features/session/session_view_data.dart` (typed state for any session UI)
  - **EDIT** `lib/app/routing/app_router.dart` — reuse the [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) redirect helper; install session's auth-required predicate; reads session state
  - **EDIT** `lib/app/dependencies.dart` — wire in-memory default + optional real override
  - **EDIT** `lib/app/app.dart` — `ProviderScope` override
  - `test/features/session/session_controller_test.dart`
  - `test/features/session/in_memory_auth_repository_test.dart`
- **Dependencies:** none for the port/controller (Flutter SDK + Riverpod). Real HTTP login
  pulls in an HTTP client when the consumer wires one — out of scope for this scaffold.

## Backend & test surface

- **Production default = `InMemoryAuthRepository`** — runs green with zero backend. `login`
  succeeds with a synthetic session **only** when seeded; otherwise it surfaces
  `common.notConnected` and never fakes success (the
  [honest-feedback guardrail](../contracts.md#13--honest-feedback-no-faked-success)).
  `logout` clears the in-memory and persisted refresh token.
- **Optional real impl** — constructed in `AppDependencies.production` only when the consumer
  provides an endpoint; never by default. Same override shape as the optional real
  [`CrashReporter`](crash-reporting.md).
- **Test server contract ([C3](../contracts.md#c3--minimal-in-repo-test-server))**
  — `tools/hono_server/` exposes the auth route group:
  - `POST /v1/auth/issue` — `{ email, password }` -> `{ accessToken, refreshToken, expiresAt, userId }`
    or `401` (`userId` seeds `AuthSession.userId`; `/refresh` inherits the same identity from the
    rotated token).
  - `POST /v1/auth/refresh` — `{ refreshToken }` -> new `{ accessToken, refreshToken, expiresAt }`
    or `401` (rotates the refresh token; the client must persist the returned `refreshToken` —
    returning only `accessToken`/`expiresAt` would lose the rotated token and break the
    issue → refresh → logout cycle).
  - `POST /v1/auth/logout` — invalidates the refresh token, `204`.
  The integration test starts the server on a random port, points the real `AuthRepository`
  impl at it, and drives the full issue -> refresh -> logout cycle.
- **Fakes** — in-memory/test only, no Mocktail: `InMemoryAuthRepository` for unit tests, the
  test server for the live network path.

## Tests

- **Unit/widget:** `session_controller_test.dart` — optimistic update + rollback on
  `AuthException`; refresh-token persisted to an `InMemorySecureStore` (assert persistence by
  reading the refresh-token key back via the fake's per-key `readString`); access token never
  persisted. `in_memory_auth_repository_test.dart` — surfaces `AuthException.notConnected`
  when unseeded.
- **Integration:** start `tools/hono_server/`, override `authRepositoryProvider` with the real
  impl pointed at it, drive login via the existing `LoginPage` callback chain, assert the
  redirect lets the user through. Use `pumpAppFrames` (8 frames), never `pumpAndSettle`.
- **Golden impact:** none directly; downstream auth-flow screens may shift copy if a session
  banner is added later.
- **Dev-gallery fixture:** a `PreviewFrame` case rendering the logged-out vs logged-in shell
  states, gated by `developmentToolsEnabled`, so the redirect behavior is deterministically
  previewable.

## i18n

- **Keys:** add `session.expired`, `session.signedOut`, `session.unavailable` to
  `lib/i18n/{en,ar,zh-Hans}.i18n.json` in sync; run `just gen`. Reuse existing
  `common.notConnected` / `globalError` where the contract already fits.
- **RTL note:** none for these strings; the login redirect target is the existing
  [`LoginPage`](../../../lib/features/auth/login_page.dart) which already handles RTL.

## Audit

- [x] **No-backend honored as a port** — pass: `AuthRepository` port + `InMemoryAuthRepository`
  default whose login/refresh/logout all throw `AuthException.notConnected` when unseeded
  (in_memory_auth_repository.dart:13-49, asserted in its test); the real `HttpAuthClient` is
  constructed only when `backendBaseUrl` is provided (dependencies.dart:341-350); the hono
  routes `POST /v1/auth/{issue,refresh,logout}` (+ register) exist at
  tools/hono_server/src/index.ts:86-183 with refresh-token rotation; the live-server e2e
  drives login → refresh (rotates + inherits userId) → logout plus honest degradation
  (test/e2e/hono_server_e2e_test.dart:131-184).
- [x] **Feature-first ownership; no core/ utils/ buckets** — pass: value object + controller +
  repositories + view data under `lib/features/session/`; real impl under
  `lib/infrastructure/auth/`.
- [x] **shared/widgets extraction only if >=3 consumers** — n/a: no widget proposed.
- [x] **Composition root confined** — pass: `authRepositoryProvider` /
  `sessionRepositoryProvider` throw `StateError`, `initialSessionProvider` defaults anonymous,
  all overridden at the `ProviderScope` (app.dart:109-111); hydration runs once from
  `_AppViewState.initState` (app.dart:218).
- [x] **Motion guarded** — n/a: no new animation; integration flows use `pumpAppFrames`
  (integration_test/development_smoke_test.dart), never gating navigation on animation.
- [x] **i18n synced en/ar/zh-Hans; gen-check stays clean** — pass (warn resolved):
  `session.expired` / `session.signedOut` / `session.unavailable` verified present in en + ar +
  zh-Hans.
- [x] **Strict-analysis clean** — pass (warn resolved): `AuthSession` is a sealed Freezed union;
  token fields are `String`; every controller log flows through `AppLogger` → `LogRedactor`
  (token/JWT/`token=` regexes scrub message, context, and `error.toString()`).
- [x] **Generated code untouched** — pass: `auth_session.freezed.dart` regenerated from the
  sealed model.
- [x] **Native entitlements flagged in PR + CI platform jobs** — n/a: no plugin (SecureStore
  entitlements are already covered by [`secure-store`](secure-store.md)).
- [x] **Golden re-baseline + dev-gallery fixture** — pass: no visual change; the
  `session_gallery_cases.dart` loggedIn/loggedOut shell fixtures exist and are registered;
  repo-wide re-baseline is outstanding (the committed baselines are outdated vs HEAD) (tracked repo-wide).
- [x] **Port-reuse consistency** — pass: refresh token persisted via the single `SecureStore`
  (`SessionRepository.refreshTokenKey`, no `clearAll`); the auth-required predicate lives inside
  the one `appRedirect` (route_guards.dart:54-59) reading live session state via
  `ProviderScope.containerOf`, with `_router.refresh()` on lifecycle resume (app.dart:283-285) —
  no per-feature redirect.
- [x] **Config rule respected** — pass: backend URL comes only from compile-time
  `AppConfig.backendBaseUrl`; the smoke test honors it via `hasBackend`.
- [x] **Honest feedback, no faked success** — pass: unseeded repo surfaces `notConnected` on
  every method; `session_controller_test.dart` proves optimistic update + rollback, that only
  the refresh token is persisted, and that the access token never touches the store;
  hydration clears a rejected refresh token instead of faking a session
  (session_controller.dart:110-125).

## Risks / notes

- **Reuses the [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) redirect
  pattern.** The shared helper is established by [`update-blocker`](update-blocker.md) or
  [`onboarding-gate`](onboarding-gate.md) (see [sequencing](../README.md#sequencing)); session
  installs its auth-required predicate into that helper. Do not invent a per-feature redirect
  mechanism or a second helper — [`biometric`](biometric.md) and [`pin-autolock`](pin-autolock.md)
  plug into the same one.
  The router is rebuild-not-reactive today (see
  [`lib/app/app.dart`](../../../lib/app/app.dart) `_AppView` keyed by config tuple), so the
  redirect reads session state synchronously from `initialSettings`-style bootstrap data, not
  from a reactive provider on the router.
- **Foreground refresh via [`lifecycle-observer`](lifecycle-observer.md).** On `resumed`, re-validate the session (the access token may have expired while backgrounded) by `ref.watch`ing `appLifecyclePhaseProvider` and calling `refresh` when needed.
- **Hard block on [`secure-store`](secure-store.md).** The refresh token must never touch
  `SharedPreferences` (plaintext). Sequence this **after** `secure-store` lands.
- **Access token in memory only.** Persist only the refresh token. On cold start, hydrate the
  session by calling `refresh` against the real `AuthRepository`; if the in-memory default is
  in place, surface `common.notConnected` rather than faking a session.
- **Optimistic update with rollback** (copy the `SettingsController._replace` shape) — flip
  `AuthSession` to authenticated immediately, roll back on `AuthException`, never leave the
  UI in a half-state.
- **Tokens are secrets.** Every log line that touches a token flows through `AppLogger` so
  [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) scrubs it; do not log
  tokens directly.
- **Logout must rotate, not just clear.** Call `AuthRepository.logout` (server-side
  invalidation) before clearing local state; if the network call fails, still clear local
  state but log the failure.
