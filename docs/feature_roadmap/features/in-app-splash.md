# Animated in-app splash

> **Tier:** P2 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** [native-splash](native-splash.md) (ship together), [onboarding-gate](onboarding-gate.md) (handoff target)

## Summary

A short branded Flutter animation (logo reveal + spinner) shown while async startup finishes, then a typed handoff to home or onboarding. The repo **already runs** the "initializing scripts" invisibly — `createApplication` awaits `AppDependencies.production` (settings load) and applies the persisted locale before `runApp`. This feature is mostly a presentation wrapper that surfaces that existing work, **not** new init logic.

## Contract

- **Ports / value objects:** `AppStartupResult` — an immutable typed value (`{buildInfo, settingsLoaded, localeApplied, error?}`) exposed from `createApplication`; `SplashViewData` (fixture-friendly, mirroring [`OnboardingFixtures`](../../lib/features/onboarding/onboarding_view_data.dart)) carrying loading / done / error states for the gallery.
- **Providers:** `appStartupResultProvider` — handwritten Riverpod holding the `Future<AppStartupResult>` (or the resolved value) forwarded from `createApplication`. No codegen.
- **Routes:** `AppRoutes.splash` + `AppRoutes.splashPath` (`'/splash'`) — **new**, **top-level** (full-screen, peer of auth/onboarding), and made the `initialLocation`.
- **Files:**
  - `lib/features/splash/splash_page.dart`, `lib/features/splash/splash_view_data.dart` — **new**.
  - [`lib/app/routing/app_routes.dart`](../../lib/app/routing/app_routes.dart) — **edit**: add the `splash` name + `splashPath` constants.
  - [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — **edit**: top-level `splash` `GoRoute`; on a resolved result, `context.goNamed(AppRoutes.home)` (or `AppRoutes.onboarding` when [onboarding-gate](onboarding-gate.md) requires it).
  - [`lib/bootstrap.dart`](../../lib/bootstrap.dart) — **edit**: `createApplication` returns/forwards the `AppStartupResult` `Future` (or accepts an `init()` future) so `SplashPage` consumes it **without re-loading**.
- **Dependencies:** none — `simple_animations` is already a dependency.

## Backend & test surface

Backend-free; the default impl is **real and local** — `createApplication` already performs the init (settings load via [`SettingsStore`](../../lib/features/settings/settings_store.dart), locale apply via `LocaleSettings`). `SplashPage` only **watches** that existing future. **Critical:** do not re-run settings/locale/`package_info` load inside the splash widget (double load, double `SharedPreferencesAsync` reads).

## Tests

- **Unit/widget:** `SplashViewData` renders loading / done / error fixtures; completed `AppStartupResult` triggers `goNamed(home)`; an error result surfaces a startup-error style message (reuse [`startup_error_view`](../../lib/app/startup/startup_error_view.dart) styling, not a new design).
- **Integration:** Reuse `createApplication`; `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`. Assert the handoff navigates **without** waiting on animation completion.
- **Golden impact:** **yes** — splash is a new full-screen visual. Re-baseline on the pinned macOS runner and add `PreviewFrame` cases (loading / done / error).
- **Dev-gallery fixture:** `PreviewFrame` cases for the three splash states, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** add a `splash` namespace — `splash.loading`, `splash.tagline`, `splash.error` — synced across `en` + `ar` (RTL) + `zh-Hans`, then `just gen`.
- **RTL note:** logo/centered layout is direction-agnostic, but re-check any directional reveal or progress affordance under `ar`.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free; consumes the existing real init.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: `lib/features/splash/` owns page + view data.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**: splash is a single routed screen.
- [x] Motion guarded — **pass**: every tween sources durations/curves from [`AppMotion`](../../lib/shared/motion/app_motion.dart) and guards with `MediaQuery.disableAnimationsOf(context)` **plus** a non-animated fallback that still calls `context.goNamed(...)`.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass** (load-bearing — see risks).
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**.
- [x] Strict-analysis clean — **pass**: typed `AppStartupResult` + `SplashViewData`, exhaustive state switch.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Golden re-baseline noted on pinned macOS runner — **warn**: new full-screen visual; re-baseline required.

## Risks / notes

- **Motion is load-bearing for tests.** The suite uses `pumpAppFrames` (8 bounded frames) and never `pumpAndSettle` ([`integration_test_support.dart`](../../integration_test/integration_test_support.dart)). The splash must **not** gate navigation on animation completion — the reduced-motion / bounded-frame path must still call `context.goNamed(home)` immediately when the startup future resolves.
- **Do not double-load.** Expose the `AppStartupResult` future from `createApplication` and poll/watch it; re-loading settings or locale inside `SplashPage` is the canonical mistake here.
- **Ship with [native-splash](native-splash.md)** — native covers the 0.5–3 s engine window (store requirement); in-app covers the smooth handoff and the branded animation. Shipping only the in-app splash leaves the native blank frame; shipping only native leaves a hard cut to live UI.
- **Handoff target:** `goNamed(AppRoutes.onboarding)` on first launch (defers to [onboarding-gate](onboarding-gate.md)) else `goNamed(AppRoutes.home)`. Read the `hasCompletedOnboarding` flag from `dependencies.initialSettings.hasCompletedOnboarding` (already loaded by `createApplication`), consistent with [onboarding-gate](onboarding-gate.md), not a second store read.
- If [update-blocker](update-blocker.md) lands its redirect first, the splash's `goNamed(home)` will be redirected to force-update transparently — order the redirects so update-blocker wins.
