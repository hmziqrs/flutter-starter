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
referral server) — but receiving needs no backend, so no `tools/test_server/` contract belongs here
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
- [x] No-backend honored as a port — **pass**: backend-free; receive-only; the `AppLinks`
  plugin is reached via the `DeepLinkService` port, never directly from a widget. **Warn:**
  magic-link *issuance* needs a server — that lives in [mfa-otp](./mfa-otp.md)/[session](./session.md), not here.
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
- **Port-reuse / sequencing:** this is the inbound-routing primitive. Build it once; re-audit
  readers when they land. Today the only firm consumers are a **future magic-link auth flow**
  (sibling to [mfa-otp](./mfa-otp.md), which reuses OTP code entry and documents no magic-link
  route — see Contract) and a future referral feature. [push-notifications](./push-notifications.md)
  resolves taps via `context.pushNamed` + `AppRoutes` helpers today, **not** via `AppLinkHandler`.
  See [../contracts.md](../contracts.md) C5 (redirect/handler reuse).
