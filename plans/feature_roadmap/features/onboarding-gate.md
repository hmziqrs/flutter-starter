# First-launch onboarding gate

> **Tier:** P1 · **Domain:** startup · **Backend:** none · **Status:** done · **Depends on:** none (reuses the existing `SettingsStore`)

## Summary

Persists a `hasCompletedOnboarding` flag and redirects first launches through `OnboardingPage` before they reach the home shell; later launches boot straight to home. Today `OnboardingPage` is **orphaned** — reachable only by direct navigation, so new users land on an empty dashboard. The highest-leverage pure-settings change in the roadmap.

## Contract

- **Ports / value objects:** Reuse the existing [`SettingsStore`](../../lib/features/settings/settings_store.dart) port (per-key `readString` / `writeString` / `remove`, **no `clearAll`**). Add a `bool hasCompletedOnboarding` field to [`SettingsState`](../../lib/features/settings/settings_state.dart).
- **Providers:** Reuse `settingsControllerProvider`; add a `markOnboardingComplete()` setter to [`SettingsController`](../../lib/features/settings/settings_controller.dart). **No new provider.** Cold start still seeds from `AppDependencies.initialSettings` (synchronous), but the redirect must read **live** controller state — `ProviderScope.containerOf(context).read(settingsControllerProvider).hasCompletedOnboarding` — so an in-session `markOnboardingComplete()` (optimistic in-memory write) is visible on the same tick as the subsequent `context.goNamed(home)`. A captured plain `bool` would re-evaluate the redirect against the stale pre-mark value and bounce home → onboarding, trapping the user until relaunch.
- **Routes:** Reuse [`AppRoutes.onboarding`](../../lib/app/routing/app_routes.dart) / `onboardingPath` (already wired). **No new route.** A `go_router` redirect is added to [`buildAppRouter`](../../lib/app/routing/app_router.dart).
- **Files:**
  - [`lib/features/settings/settings_state.dart`](../../lib/features/settings/settings_state.dart) — **edit**: `+hasCompletedOnboarding` (default `false`), `copyWith`, `==`/`hashCode`.
  - [`lib/features/settings/settings_repository.dart`](../../lib/features/settings/settings_repository.dart) — **edit**: add an `onboardingKey` to `persistedKeys`, load + save it (write `"true"`/`"false"` or `remove`).
  - [`lib/features/settings/settings_controller.dart`](../../lib/features/settings/settings_controller.dart) — **edit**: `markOnboardingComplete()` setter (optimistic write through the repo).
  - [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — **edit**: compose the onboarding predicate into the **existing** top-level `_redirectSettingsDeepLinks` redirect (see [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused) — go_router allows one redirect callback; do not add a second). The cold-start seed parameter is `bool hasCompletedOnboarding` (same polarity as the `SettingsState` field and the value passed from `createApplication`); any shell-tab destination (`homePath` / pricing / settings) → `onboardingPath` when the flag is unset.
  - [`lib/bootstrap.dart`](../../lib/bootstrap.dart) — **edit**: pass `dependencies.initialSettings.hasCompletedOnboarding` into `buildAppRouter` from `createApplication`.
- **Dependencies:** none.

## Backend & test surface

Backend-free; [`SettingsStore`](../../lib/features/settings/settings_store.dart) is the existing per-key port and [`SharedPreferencesSettingsStore`](../../lib/infrastructure/preferences/shared_preferences_settings_store.dart) is the sole production impl. No network, no new port, no faked success.

## Tests

- **Unit/widget:** `SettingsRepository` round-trips `hasCompletedOnboarding` (true/false/missing → default false); `markOnboardingComplete()` persists; redirect sends any shell-tab destination (`homePath`/pricing/settings) → `onboardingPath` when unset and is a no-op when set; redirect does **not** trap users already on onboarding/auth routes.
- **Integration:** Reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`. Fresh install (`InMemorySettingsStore`) flows to onboarding; the in-session transition `OnboardingPage.onSkip` → `markOnboardingComplete()` → `context.goNamed(home)` reaches home **without a relaunch** (regresses the captured-bool loop); fresh-install deep links to `/pricing` and `/settings` redirect to onboarding; after `markOnboardingComplete()` + relaunch, boots to home.
- **Golden impact:** **warn** — redirect changes the initial screen for fresh installs; any golden that boots at `homePath` by default may need a re-baseline or a fixture that pre-sets the flag.
- **Dev-gallery fixture:** n/a (behavior, no new visual); optionally a `PreviewFrame` toggle that flips the flag for manual preview.

## i18n

- **Keys:** none new — the `onboarding` namespace already exists ([`lib/i18n/en.i18n.json`](../../lib/i18n/en.i18n.json)).
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **pass**: reuses the existing `SettingsStore` port; `onboardingKey` loads/persists through `SettingsRepository` (`lib/features/settings/settings_repository.dart:69,94`); no faked success — `markOnboardingComplete()` rolls back the optimistic flag when persistence fails (`test/features/settings/settings_onboarding_test.dart:92`).
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: edits confined to `lib/features/settings/*` plus the [C5](../contracts.md#c5--one-go_router-redirect-pattern-reused)-owned redirect under `lib/app/routing/`.
- [x] shared/widgets extraction >=3 consumers — **n/a**: no widget extracted.
- [x] Composition root confined — **pass**: the predicate composes into the **single** `appRedirect` (`lib/app/routing/route_guards.dart:46-52`) wired as the one `go_router` redirect (`app_router.dart:50-54`); the redirect reads live state via `ProviderScope.containerOf(...).read(settingsControllerProvider)` (`route_guards.dart:97-104`); the cold-start seed flows from `initialSettings` through `_AppViewState` (`lib/app/app.dart:195`).
- [x] Motion guarded — **n/a**: no animation.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**: no new keys; the `onboarding` namespace pre-existed.
- [x] Strict-analysis clean — **pass**: typed `bool hasCompletedOnboarding` in `SettingsState` with `copyWith`/`==`/`hashCode` (`settings_state.dart:41,87,112,128`); no `dynamic`.
- [x] Generated code untouched — **pass**: source-level change only; `settings_state.freezed.dart` regenerated via `just gen`.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: no native config.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: behavior-only change (fixture n/a); the boot-state golden impact is documented in Tests — repo-wide re-baseline pending the pinned macOS 26 CI run (tracked repo-wide, not per-feature).
- [x] Port-reuse consistency — **pass**: no new port; reuses `SettingsStore`; the gate reuses the one `appRedirect` chain, ordered after force-update (`route_guards.dart:34-52`) as required.
- [x] Config rule respected — **pass**: no env gating.
- [x] Honest feedback, no faked success — **pass**: completion persists before navigation in all three home callbacks (`_completeOnboardingAndGoHome`, `lib/features/onboarding/onboarding_routes.dart:49-53`); persistence failure surfaces via rollback (tested).
- [x] Tests — **pass**: `test/features/settings/settings_onboarding_test.dart` (round-trip true/false/missing/legacy values, persist, rollback, `persistedKeys`); `test/app/routing/app_router_onboarding_redirect_test.dart` (fresh install → onboarding, returning user → home, in-session Skip / paywall Skip / paywall Continue reach home without relaunch, `/pricing` + `/settings` deep links redirect, no loop on onboarding/auth, relaunch after completion) — all via the real `App` with `pumpAppFrames`.

## Risks / notes

- **Avoid the redirect loop (load-bearing).** Because the redirect reads **live** controller state (see Providers), `markOnboardingComplete()`'s optimistic in-memory write is visible on the same tick — the loop cannot occur as long as the redirect does not capture a stale bool. Every home-navigating callback must still call `markOnboardingComplete()` before `context.goNamed(home)`: `OnboardingPage.onSkip`, the paywall `onContinue`, **and** `PaywallPage.onSkip` (all three live in [`app_router.dart`](../../lib/app/routing/app_router.dart)). An integration test covers the in-session Skip → home path.
- **Redirect helper ownership ([C5](../contracts.md#c5--one-go_router-redirect-pattern-reused)).** The router already has one top-level redirect (`_redirectSettingsDeepLinks`); this feature **composes its predicate into that existing callback** rather than adding a second (go_router accepts one redirect). Coordinate with [update-blocker](update-blocker.md) so the predicates chain in order (force-update first, then onboarding). Do not invent a second redirect mechanism.
- **Redirect must skip already-auth/onboarding routes** — only redirect when the destination is `homePath` (and the shell tabs) and the flag is unset, so deep links and auth flows aren't hijacked.
- **Ordering vs.** [update-blocker](update-blocker.md): a hard update block must win over the onboarding redirect — chain redirects so force-update is evaluated first.
- Settings load is synchronous into `initialSettings` inside `createApplication` for cold-start seeding, but the redirect reads **live** `settingsControllerProvider` state (see Providers) so in-session completion is visible without a relaunch. If the live read is ever dropped in favor of a captured bool, a `refreshListenable` becomes mandatory — the captured-bool design regresses the redirect loop.
