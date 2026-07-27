# Native splash

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** none (ship alongside [in-app-splash](in-app-splash.md))

## Summary

A codegen-driven branded launch screen (background color + logo) rendered by native iOS/Android code during the 0.5–3 s engine-init window, before Dart UI is on screen. Every shipped mobile app needs one — without it users see a blank frame and assume a crash, and stores reject submissions that lack a launch storyboard/resource.

## Contract

- **Ports / value objects:** none. This is a **config/codegen concern, not Dart** — it deliberately bypasses the feature-first and no-backend rules (there is no `lib/` code and no port).
- **Providers:** none.
- **Routes:** none.
- **Files:**
  - `flutter_native_splash.yaml` — **new** (repo root). Sources the brand background from the accent token (neutral default) in [`lib/shared/theme/forui_theme_factory.dart`](../../lib/shared/theme/forui_theme_factory.dart) (`_accentColors`) and the logo from `assets/brand/`.
  - `assets/brand/logo_light.png`, `assets/brand/logo_dark.png` — **new** brand assets (tracked in [`docs/release_readiness.md`](../release_readiness.md) as a release blocker).
  - [`justfile`](../../justfile) — **edit**: add `splash` / `splash-remove` recipes mirroring the existing `gen` / `gen-check` pattern (`dart run flutter_native_splash:create`); commit the generated native output.
  - Generated (committed, never hand-edit): iOS `LaunchScreen.storyboard` rewrite, Android drawable, web favicon — all outside `lib/`.
- **Dependencies:** `flutter_native_splash` (**dev** dependency — runs the create CLI; not compiled into the app).

## Backend & test surface

Backend-free; there is no Dart runtime component, no port, and no network. The "default" is the committed codegen output; regeneration is a `just` recipe, not a runtime path. Only the stock `LaunchTheme`/`NormalTheme` meta-data and a default `LaunchScreen.storyboard` exist today.

## Tests

- **Unit/widget:** n/a — no Dart.
- **Integration:** the dev smoke ([`integration_test/development_smoke_test.dart`](../../integration_test/development_smoke_test.dart)) will display the native splash for the brief engine window; no assertion is added. Regeneration correctness is enforced by the `just splash` recipe + review of the committed native diff.
- **Golden impact:** none — the native layer is below Flutter and not captured by the golden matrix.
- **Dev-gallery fixture:** n/a (pre-Flutter surface).

## i18n

- **Keys:** none.
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **n/a**: pure codegen, no port.
- [x] Feature-first ownership; no core/ utils/ buckets — **n/a**: config/codegen, not Dart — correctly bypasses `lib/features`.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**.
- [x] Motion guarded — **n/a**: native, not `AppMotion`-governed.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **n/a**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**.
- [x] Strict-analysis clean — **n/a** (no Dart).
- [x] Native entitlements flagged in PR + CI platform jobs — **warn**: edits native files outside `lib/` (iOS storyboard, Android drawable, web favicon); flag the native churn in the PR and ensure the iOS/Android/macOS build jobs in [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) still pass.
- [x] Golden re-baseline noted on pinned macOS runner — **n/a**.

## Risks / notes

- **Brand assets are a release blocker** — `assets/brand/logo_{light,dark}.png` do not exist yet; track in [`docs/release_readiness.md`](../release_readiness.md).
- **Accent must match the theme.** Pin the splash background to the same accent value [`ForuiThemeFactory._accentColors`](../../lib/shared/theme/forui_theme_factory.dart) ships as the neutral default; do not introduce a divergent brand color.
- **Ship with [in-app-splash](in-app-splash.md) in the same PR** — native covers the engine window, in-app covers the handoff to live UI. Shipping only one leaves either a blank gap or a double splash.
- **Platform coverage:** iOS / Android / macOS are supported by the starter's targets; web is optional. Verify `flutter_native_splash:create` emits for each enabled platform.
- Regenerating overwrites native files — review the committed diff every time (do not blindly accept the CLI output).
