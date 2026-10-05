# Native splash

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** done · **Depends on:** none (ship alongside [in-app-splash](in-app-splash.md))

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

- [x] No-backend honored as a port — **n/a**: pure codegen, no port, no Dart runtime path.
- [x] Feature-first ownership; no core/ utils/ buckets — **n/a**: config/codegen, not Dart — correctly bypasses `lib/features` (repo root `flutter_native_splash.yaml`).
- [x] shared/widgets extraction >=3 consumers — **n/a**.
- [x] Composition root confined — **n/a**: no providers; regeneration is a `just` recipe (`justfile:58-63` `splash` / `splash-remove`).
- [x] Motion guarded — **n/a**: native, not `AppMotion`-governed.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**: no strings.
- [x] Strict-analysis clean — **n/a** (no Dart; `flutter_native_splash: ^2.4.8` is a `dev_dependencies` entry, `pubspec.yaml:59`).
- [x] Generated code untouched — **pass**: native output committed from the CLI (never hand-edited); regeneration is reviewable via `just splash` + committed diff.
- [x] Native entitlements flagged in PR + CI platform jobs — **pass** (warn resolved): native output landed and committed — iOS `ios/Runner/Base.lproj/LaunchScreen.storyboard` (LaunchBackground + LaunchImage imageViews) + `Assets.xcassets/{LaunchBackground,LaunchImage}.imageset`; Android `res/drawable/{launch_background,background}.xml/.png`, `values-v31/styles.xml` (`windowSplashScreenBackground` `#171717`, lines 9-11) with `values-night*` variants; web `web/splash/img` + `web/favicon.png`. Platform builds covered by `.github/workflows/release.yml` (apple on `macos-26`, android, windows, linux).
- [x] Goldens re-baselined + dev-gallery fixture — **n/a**: pre-Flutter surface, below the golden matrix.
- [x] Port-reuse consistency — **n/a**: no port.
- [x] Config rule respected — **pass**: background pinned to the neutral-default primary token (`#171717`/`#E5E5E5`) matching `ForuiThemeFactory._accentColors`, documented in the yaml header (`flutter_native_splash.yaml:7-16`).
- [x] Honest feedback, no faked success — **n/a**.
- [x] Brand assets — **pass** (noted): `assets/brand/logo_{light,dark}.png` committed as tracked placeholders; yaml header flags them for replacement per `docs/release_readiness.md`.

## Risks / notes

- **Brand assets are a release blocker** — `assets/brand/logo_{light,dark}.png` do not exist yet; track in [`docs/release_readiness.md`](../release_readiness.md).
- **Accent must match the theme.** Pin the splash background to the same accent value [`ForuiThemeFactory._accentColors`](../../lib/shared/theme/forui_theme_factory.dart) ships as the neutral default; do not introduce a divergent brand color.
- **Ship with [in-app-splash](in-app-splash.md) in the same PR** — native covers the engine window, in-app covers the handoff to live UI. Shipping only one leaves either a blank gap or a double splash.
- **Platform coverage:** iOS / Android / macOS are supported by the starter's targets; web is optional. Verify `flutter_native_splash:create` emits for each enabled platform.
- Regenerating overwrites native files — review the committed diff every time (do not blindly accept the CLI output).
