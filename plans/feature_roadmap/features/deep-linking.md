# Deep linking

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** in-progress · **Depends on:** none
>
> Implementation-audit gap (2026-10-04): resolver/allowlist/cold-start are implemented and
> exhaustively unit-tested, but the claimed integration coverage is missing at the wiring level —
> no test pushes a URI through the stream and asserts the router lands on the named destination
> (`app.dart:254-271` `_listenAppLinkStream`/`_dispatchAppLink` untested), and no bootstrap-level
> test asserts the cold-start link seeds `initialLocation`
> (`bootstrap.dart` `_initialLocationFromResolvedLink` untested).

## Summary
Intercept inbound native URIs (iOS Universal Links, Android App Links, custom schemes) and route them
to named `go_router` destinations — including the cold-start initial link. Re-engagement (email magic
links, reset-password links, referral/share URLs, push deep links) and auth-recovery depend on it;
today links just open the app at home and lose context. Receive-only — no backend — but it needs
per-platform native association config.

## Contract
- **Ports / value objects:** `AppLinkHandler` — resolves a `Uri` into a typed `ResolvedLink`
  (`(String routeName, Map<String,String> params)`) or `null` for unhandled/foreign hosts. Reuses the
  existing `AppRoutes` name+path constants and the `AppRoutes.otpLocation(...)`-style helper pattern.
  Host/path matching is driven by an allowlist sourced from compile-time `AppConfig` (never arbitrary
  hosts).
- **Providers:** `appLinkHandlerProvider` — handwritten Riverpod over a `DeepLinkService` that
  owns the `AppLinks` instance and exposes `Stream<ResolvedLink> get links` +
  `Future<ResolvedLink?> getInitialLink()`. Construct the real adapter in
  [`lib/app/dependencies.dart`](../../../lib/app/dependencies.dart) (or `bootstrap.dart` when the
  cold-start `getInitialLink()` must precede `buildAppRouter`); override at the `ProviderScope` in
  [`lib/app/app.dart`](../../../lib/app/app.dart). `_AppViewState` `ref.listen`s the stream and
  dispatches via `context.goNamed`/`pushNamed` — it never names `AppLinks` directly (a widget must
  not call a platform-channel plugin; checklist #1/#4). Tests override the provider with a
  `StreamController<Uri>`-backed fake — no Mocktail, no codegen.
- **Routes:** consumes existing routes (`login`, `otp`, `resetPassword`, `home`). Adds a
  `magicLink`/`/auth/magic-link` constant **only if** a magic-link auth flow is introduced; otherwise
  no new routes. No redirect — inbound links call `context.goNamed`/`pushNamed` directly.
- **Files:**
  - `lib/app/routing/app_link_handler.dart` — **add**; `Uri` → `ResolvedLink?` resolver + allowlist.
  - `lib/app/app.dart` — **edit (root composition)**; override `appLinkHandlerProvider` at
    the `ProviderScope`; in `_AppViewState` `ref.listen` the handler's `links` stream, dispatch
    resolved links, dispose on unmount.
  - `lib/bootstrap.dart` — **edit (root composition)**; capture the cold-start initial link
    (`getInitialLink`) and feed it as `initialLocation` into `buildAppRouter`.
  - `lib/app/routing/app_router.dart` — **edit**; `buildAppRouter` already accepts `initialLocation`.
  - `lib/app/config/app_config.dart` — **edit**; add a compile-time allowed-deep-link-hosts define
    (string list), gated exactly like the existing compile-time config (no runtime fallback).
  - `ios/Runner/Runner.entitlements` — **edit (native)**; `applinks:associated-domains`.
  - `android/app/src/main/AndroidManifest.xml` — **edit (native)**; `autoVerify` intent-filter.
  - `apple-app-site-association` + `assetlinks.json` — **add (native, hosted server-side)**.
- **Dependencies:** `app_links` (the maintained successor to `uni_links`). Not currently in
  `pubspec.lock`.

## Backend & test surface
Backend-free. The receiver is local; the default impl is the real `AppLinks`, owned by the
`DeepLinkService` behind `appLinkHandlerProvider`. The feature only *matters* once a server
**issues** links (magic-link auth via [mfa-otp](./mfa-otp.md) / [session](./session.md), or a
referral server) — but receiving needs no backend, so no `tools/hono_server/` contract belongs here
(issuance is owned by those server features). Tests override `appLinkHandlerProvider` with a fake
driven by a `StreamController<Uri>` — no Mocktail.

## Tests
- **Unit/widget:** `AppLinkHandler.resolve` over: known route + params, unknown path (→ `null`),
  foreign host (→ `null`, phishing rejection), malformed `Uri`. Exhaustive over supported routes.
- **Integration:** push fake URIs through the stream, assert the router lands on the named
  destination (reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`). Assert cold-start
  initial link seeds `initialLocation`.
- **Golden impact:** none (routing, no visual surface).
- **Dev-gallery fixture:** n/a in `PreviewFrame`; optionally a `/dev/diagnostics` trigger to simulate
  an inbound link for manual QA.

## i18n
- **Keys:** reuse existing `routeError` for unhandled links; add `deepLink.unsupported` only if a
  user-visible toast is desired for rejected links. Sync `en` + `ar` + `zh-Hans`, run `just gen`.
- **RTL note:** n/a (routing).

## Audit

Implementation audit (2026-10-04) against the 13-item checklist in
[contracts.md](../contracts.md):

- [x] No-backend honored as a port — **warn**: backend-free receive-only; the `AppLinks` plugin
  is reached only via `AppLinksDeepLinkService`/`AppLinkInbox` (`app_link_handler.dart`) — no
  other `lib/` file imports `app_links` (grep-verified); no widget calls a plugin. The warn is
  the missing wiring-level integration coverage this doc claims: no test asserts a streamed URI
  lands the router on the named destination (`app.dart:254-271` untested) or that the cold-start
  link seeds `initialLocation` (`bootstrap.dart` `_initialLocationFromResolvedLink` untested;
  only service-level `getInitialLink` is covered, `app_link_handler_test.dart:219-235,274-285`).
- [x] Feature-first ownership — **pass**: handler lives under `lib/app/routing/` (composition-root-
  adjacent, the correct home for routing concerns — not a feature bucket); no `core/`/`utils/`.
- [x] Shared extraction ≥3 consumers — **n/a**: no widget extracted.
- [x] Composition root confined — **pass**: `RouteAppLinkHandler(allowedHosts:)` constructed only
  in `AppDependencies.production` (`dependencies.dart:415-417`, Noop in `inMemory` at :166);
  `appLinkHandlerProvider` overridden only at the `ProviderScope` (`app.dart:145`); the cold-start
  link is captured inside `createApplication` **before** `initialLocation` reaches
  `buildAppRouter` (`bootstrap.dart`).
- [x] Motion guarded — **n/a**: routing only.
- [x] i18n synced en/ar/zh-Hans — **pass**: reuse only, as planned (no `deepLink.*` key added and
  none needed; rejected links resolve to `null`, no toast).
- [x] Strict analysis clean — **pass**: exhaustive switches over route paths
  (`app_link_handler.dart` `_staticRouteFor` + `_tryResolveOtp`; `bootstrap.dart`
  `_initialLocationFromResolvedLink`); typed `ResolvedLink` with value equality.
- [x] Generated code untouched — **n/a**: no generated code.
- [x] Native entitlements flagged — **pass**: landed — `com.apple.developer.associated-domains`
  in `ios/Runner/Runner.entitlements` + `Release.entitlements` (empty by default with consumer
  instructions in comments) and the `autoVerify` intent-filter in
  `android/app/src/main/AndroidManifest.xml` (placeholder host documented); hosted
  `apple-app-site-association`/`assetlinks.json` remain consumer-side by design, mirrored by the
  compile-time `ALLOWED_DEEP_LINK_HOSTS` define (`app_config.dart:44-46`, present in all
  `config/*.json`).
- [x] Goldens re-baselined + dev-gallery fixture — **n/a**: no visual surface (doc: n/a).
- [x] Port-reuse consistency — **pass**: single inbound-routing primitive; push taps still use
  `context.pushNamed` directly, not this handler, exactly as this doc records.
- [x] Config rule respected — **pass**: allowlist is compile-time only
  (`AllowedDeepLinkHosts.parse(String.fromEnvironment(...))`, no runtime fallback); empty
  allowlist disables inbound routing (tested `app_link_handler_test.dart:23-27,183-191`).
- [x] Honest feedback, no faked success — **pass**: foreign hosts/phishing and unknown paths
  resolve to `null` and are dropped — never navigated (`app_link_handler_test.dart:161-191`); an
  empty allowlist rejects every URI rather than guessing.

## Risks / notes
- **Cold-start race.** The initial link must be captured in `createApplication` **before**
  `buildAppRouter` consumes `initialLocation`, or the deep link is lost on first launch.
- **Host allowlist is a security boundary.** Resolve only against hosts in compile-time `AppConfig`;
  accepting arbitrary hosts lets a malicious site route users into auth flows (phishing). Never
  branch on raw `enable*` flags — gate through config like the rest of the app.
- **Web is already handled** by `MaterialApp.router` (browser URL bar); `app_links` is the mobile
  path. Don't double-wire web.
- **Native association files are server-hosted**, not in the binary — CI can validate the entitlement
  is present but cannot prove the `/.well-known/` endpoints serve correctly; call this out in the PR.
- **Port-reuse / sequencing:** this is the inbound-routing primitive. Build it once; re-audit
  readers when they land. Today the only firm consumers are a **future magic-link auth flow**
  (sibling to [mfa-otp](./mfa-otp.md), which reuses OTP code entry and documents no magic-link
  route — see Contract) and a future referral feature. [push-notifications](./push-notifications.md)
  resolves taps via `context.pushNamed` + `AppRoutes` helpers today, **not** via `AppLinkHandler`.
  See [../contracts.md](../contracts.md) C5 (redirect/handler reuse).
