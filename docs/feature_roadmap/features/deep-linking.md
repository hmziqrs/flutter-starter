# Deep linking

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** planned · **Depends on:** none

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
- **Providers:** none required. Wiring is imperative in `_AppViewState` (subscribe to
  `AppLinks().uriLinkStream`) and in `createApplication` (cold-start initial link), consistent with
  the router being rebuilt-not-reactive. If a consumer later wants reactive access, expose a
  handwritten `StreamProvider<ResolvedLink>` overridden at the `ProviderScope` — not codegen.
- **Routes:** consumes existing routes (`login`, `otp`, `resetPassword`, `home`). Adds a
  `magicLink`/`/auth/magic-link` constant **only if** a magic-link auth flow is introduced; otherwise
  no new routes. No redirect — inbound links call `context.goNamed`/`pushNamed` directly.
- **Files:**
  - `lib/app/routing/app_link_handler.dart` — **add**; `Uri` → `ResolvedLink?` resolver + allowlist.
  - `lib/app/app.dart` — **edit (root composition)**; in `_AppViewState` subscribe to
    `uriLinkStream`, dispatch resolved links, dispose on unmount.
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
Backend-free. The receiver is local; the default impl is the real `AppLinks`. The feature only
*matters* once a server **issues** links (magic-link auth via [mfa-otp](./mfa-otp.md) /
[session](./session.md), or a referral server) — but receiving needs no backend, so no
`tools/test_server/` contract belongs here (issuance is owned by those server features). Tests drive
a fake `AppLinks` via a `StreamController<Uri>` — no Mocktail.

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
- [x] No-backend honored as a port — **n/a**: backend-free; receive-only. **Warn:** magic-link
  *issuance* needs a server — that lives in [mfa-otp](./mfa-otp.md)/[session](./session.md), not here.
- [x] Feature-first ownership; no `core/` `utils/` buckets — **pass**: handler lives under
  `lib/app/routing/` (composition-root-adjacent, the correct home for routing concerns — not a
  feature bucket).
- [x] shared/widgets extraction only if >=3 consumers — **n/a**.
- [x] Motion guarded — **n/a**.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (mostly reuse).
- [x] Strict-analysis clean — **pass**: exhaustive switch over resolved routes; typed `ResolvedLink`.
- [ ] Native entitlements flagged in PR + CI platform jobs — **warn**: iOS associated-domains
  entitlement + hosted `apple-app-site-association`; Android `autoVerify` + hosted `assetlinks.json`
  — all must be documented in the PR and verified outside CI (CI cannot host the association files).
- [x] Golden re-baseline noted on pinned macOS runner — **n/a**.

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
- **Port-reuse / sequencing:** this is the inbound-routing primitive consumed by
  [mfa-otp](./mfa-otp.md) (magic-link auth), the referral feature, and [push-notifications](./push-notifications.md)
  tap handling (which already plans to resolve via `context.pushNamed` + `AppRoutes` helpers). Build
  it once; those features read it. See [../decisions.md](../decisions.md) D5 (redirect/handler reuse).
