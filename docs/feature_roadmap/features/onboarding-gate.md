# First-launch onboarding gate

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** none (reuses the existing `SettingsStore`)

## Summary

Persists a `hasCompletedOnboarding` flag and redirects first launches through `OnboardingPage` before they reach the home shell; later launches boot straight to home. Today `OnboardingPage` is **orphaned** — reachable only by direct navigation, so new users land on an empty dashboard. The highest-leverage pure-settings change in the roadmap.

## Contract

- **Ports / value objects:** Reuse the existing [`SettingsStore`](../../lib/features/settings/settings_store.dart) port (per-key `readString` / `writeString` / `remove`, **no `clearAll`**). Add a `bool hasCompletedOnboarding` field to [`SettingsState`](../../lib/features/settings/settings_state.dart).
- **Providers:** Reuse `settingsControllerProvider`; add a `markOnboardingComplete()` setter to [`SettingsController`](../../lib/features/settings/settings_controller.dart). **No new provider** — settings load synchronously into `AppDependencies.initialSettings` inside `createApplication`, so the router reads a plain `bool` and stays rebuild-not-reactive.
- **Routes:** Reuse [`AppRoutes.onboarding`](../../lib/app/routing/app_routes.dart) / `onboardingPath` (already wired). **No new route.** A `go_router` redirect is added to [`buildAppRouter`](../../lib/app/routing/app_router.dart).
- **Files:**
  - [`lib/features/settings/settings_state.dart`](../../lib/features/settings/settings_state.dart) — **edit**: `+hasCompletedOnboarding` (default `false`), `copyWith`, `==`/`hashCode`.
  - [`lib/features/settings/settings_repository.dart`](../../lib/features/settings/settings_repository.dart) — **edit**: add an `onboardingKey` to `persistedKeys`, load + save it (write `"true"`/`"false"` or `remove`).
  - [`lib/features/settings/settings_controller.dart`](../../lib/features/settings/settings_controller.dart) — **edit**: `markOnboardingComplete()` setter (optimistic write through the repo).
  - [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — **edit**: `buildAppRouter` takes a `bool requireOnboarding` and installs the redirect helper (see [D5](../decisions.md#d5--one-go_router-redirect-pattern-reused)); `homePath` → `onboardingPath` when the flag is unset.
  - [`lib/bootstrap.dart`](../../lib/bootstrap.dart) — **edit**: pass `dependencies.initialSettings.hasCompletedOnboarding` into `buildAppRouter` from `createApplication`.
- **Dependencies:** none.

## Backend & test surface

Backend-free; [`SettingsStore`](../../lib/features/settings/settings_store.dart) is the existing per-key port and [`SharedPreferencesSettingsStore`](../../lib/infrastructure/preferences/shared_preferences_settings_store.dart) is the sole production impl. No network, no new port, no faked success.

## Tests

- **Unit/widget:** `SettingsRepository` round-trips `hasCompletedOnboarding` (true/false/missing → default false); `markOnboardingComplete()` persists; redirect sends `homePath` → `onboardingPath` when unset and is a no-op when set; redirect does **not** trap users already on onboarding/auth routes.
- **Integration:** Reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`. Fresh install (`InMemorySettingsStore`) flows to onboarding; after `markOnboardingComplete()` + relaunch, boots to home.
- **Golden impact:** **warn** — redirect changes the initial screen for fresh installs; any golden that boots at `homePath` by default may need a re-baseline or a fixture that pre-sets the flag.
- **Dev-gallery fixture:** n/a (behavior, no new visual); optionally a `PreviewFrame` toggle that flips the flag for manual preview.

## i18n

- **Keys:** none new — the `onboarding` namespace already exists ([`lib/i18n/en.i18n.json`](../../lib/i18n/en.i18n.json)).
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free; reuses the existing `SettingsStore`.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: edits are feature-local in `lib/features/settings/` plus one router line.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**.
- [x] Motion guarded — **n/a**.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**: no new keys.
- [x] Strict-analysis clean — **pass**: typed `bool`, no `dynamic`.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Golden re-baseline noted on pinned macOS runner — **warn**: initial-route change may shift boot-state goldens.

## Risks / notes

- **Avoid the redirect loop.** `OnboardingPage.onSkip` / the paywall `onContinue` must call `markOnboardingComplete()` **before** `context.goNamed(home)` — otherwise the redirect immediately bounces back to onboarding. Wire this into the existing callbacks in [`app_router.dart`](../../lib/app/routing/app_router.dart).
- **Redirect helper ownership ([D5](../decisions.md#d5--one-go_router-redirect-pattern-reused)).** This feature and [update-blocker](update-blocker.md) are both candidates to introduce the first redirect. Coordinate so **one** of them lands the shared helper in `buildAppRouter`; the other reuses it. Do not invent two redirect mechanisms.
- **Redirect must skip already-auth/onboarding routes** — only redirect when the destination is `homePath` (and the shell tabs) and the flag is unset, so deep links and auth flows aren't hijacked.
- **Ordering vs.** [update-blocker](update-blocker.md): a hard update block must win over the onboarding redirect — chain redirects so force-update is evaluated first.
- Settings load is synchronous into `initialSettings` inside `createApplication`, so the router keeps its current rebuild-not-reactive model — no `refreshListenable` plumbing required.
