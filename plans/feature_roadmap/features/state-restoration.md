# State restoration + last-screen persistence

> **Tier:** P3 · **Domain:** startup · **Backend:** none · **Status:** in-progress · **Depends on:** none (pairs with [lifecycle-observer](lifecycle-observer.md))

> Implementation audit 2026-10-04: all code paths landed (`restorationScopeId`, per-page
> `RestorationMixin`, last-route persistence + restore). Remaining gap is test coverage the doc
> claims but the repo lacks — no end-to-end test that a seeded `nav.last_route` re-opens through
> `createApplication`, and no explicit `restorationScopeId`-constant assertion (details in the
> Audit block) — hence `in-progress`, not `done`.

## Summary

Restores ephemeral UI state (in-progress form drafts, onboarding page index, scroll position) after the OS reclaims the backgrounded process, via Flutter's `RestorationScope` + `RestorationMixin`. Optionally persists the last route so a relaunched app returns to where the user left off. Low effort, limited immediate payoff (the stateful surface is small today), but it prevents the "I lost my place" data-loss feeling on memory-constrained devices.

## Contract

- **Ports / value objects:** Reuse the existing [`SettingsStore`](../../lib/features/settings/settings_store.dart) port (per-key, **no `clearAll`**) for the optional last-route key only. Restoration IDs are plain `String` constants. No new value objects.
- **Providers:** **none new** — restoration is a Flutter framework mechanism (`restorationScopeId` + `RestorationMixin`), not a Riverpod concern.
- **Routes:** none new. The optional last-route sub-feature reads a saved path and passes it as `initialLocation` ([`App` already accepts `initialLocation`](../../lib/app/app.dart)).
- **Files:**
  - [`lib/app/app.dart`](../../lib/app/app.dart) — **edit**: add `restorationScopeId: 'app'` to `MaterialApp.router` (constant ID).
  - [`lib/features/auth/login_presentation_state.dart`](../../lib/features/auth/login_presentation_state.dart) (+ `register_`, `forgot_password_`, `otp_`, `reset_password_`) — **edit**: mix in `RestorationMixin` to restore the email/OTP draft.
  - [`lib/features/onboarding/onboarding_page.dart`](../../lib/features/onboarding/onboarding_page.dart) — **edit**: make the `PageController` page index restorable (it currently holds `_page` + a `PageController(initialPage:)`).
  - [`lib/features/profile/update_profile_page.dart`](../../lib/features/profile/update_profile_page.dart) — **edit**: restore the in-progress profile draft.
  - **Optional last-route:** [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — **edit**: a `GoRouter` `Observer` writes route changes to a `SettingsStore` key; [`lib/bootstrap.dart`](../../lib/bootstrap.dart) — **edit**: read the saved path in `createApplication` and pass it as `initialLocation`.
- **Dependencies:** none.

## Backend & test surface

Backend-free; restoration is Flutter framework state. The optional last-route persistence reuses the existing [`SettingsStore`](../../lib/features/settings/settings_store.dart) port with [`SharedPreferencesSettingsStore`](../../lib/infrastructure/preferences/shared_preferences_settings_store.dart) as the sole production impl — per-key `readString`/`writeString`/`remove`, no new port, no network.

## Tests

- **Unit/widget:** restoration round-trips the login email draft, the onboarding page index, and the profile draft after a simulated process death (`tester.restoration` / `RestorationBubble`); `restorationScopeId` is constant; pages still build with restoration disabled.
- **Integration:** Reuse `createApplication`; `pumpAppFrames`, never `pumpAndSettle`. Verify a restored route re-opens and that [onboarding-gate](onboarding-gate.md) / [update-blocker](update-blocker.md) redirects still win over a saved last-route.
- **Golden impact:** **warn** — `RestorationMixin` adds a wrapper that can shift pixel output; re-baseline if any restored page participates in the canonical matrix.
- **Dev-gallery fixture:** n/a (framework mechanism); optionally a `PreviewFrame` that restores a draft for manual verification.

## i18n

- **Keys:** none new.
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **pass**: backend-free; reuses `SettingsStore` for the last-route key only (`lib/app/last_route.dart` `writeString` under `nav.last_route`; read in `lib/bootstrap.dart:144-166`); no `clearAll`, no faked success.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: `RestorationMixin` edits are feature-local (auth pages, `onboarding_page.dart:34-46`, `update_profile_page.dart:68-141`); the shared binding lives under `lib/shared/forms/restorable_text_controller.dart` with five page consumers.
- [x] shared/widgets extraction >=3 consumers — **pass**: `RestorableTextControllerBinding` (shared/forms) consumed by login, register, forgot-password, otp, and update-profile pages (>=3 concrete).
- [x] Composition root confined — **pass**: `LastRouteObserver` constructed only as a router observer in `_AppViewState` (`lib/app/app.dart:198`); last-route read confined to `createApplication`; `restorationScopeId: 'app'` is one `MaterialApp.router` line (`app.dart:335`).
- [x] Motion guarded — **n/a**: no animation.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**: no new keys.
- [x] Strict-analysis clean — **pass**: typed `RestorableString`/`RestorableStringN` drafts; exhaustive `pathForLastRouteName` switch over route names (`last_route.dart:11-44`); no `dynamic`.
- [x] Generated code untouched — **pass**: no generated files in scope.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**: no native config.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: fixture n/a (framework mechanism) as documented; `RestorationMixin` golden impact documented in Tests — repo-wide re-baseline pending the pinned macOS 26 CI run (tracked repo-wide, not per-feature).
- [x] Port-reuse consistency — **pass**: reuses `SettingsStore` (no parallel persistence port); the observer reuses the router `observers:` seam like analytics.
- [x] Config rule respected — **pass**: dev-only routes excluded from last-route persistence (`pathForLastRouteName` returns null for `developmentScreens`/`diagnostics`), asserted in `test/app/state_restoration_test.dart:53-57`.
- [x] Honest feedback, no faked success — **pass**: store failures never throw and never block navigation (`runGuarded` around every write, `last_route.dart:76-88`; tested 'never throws and never blocks').
- [ ] Tests as claimed — **warn**: per-page restoration is covered (`test/features/auth/login_presentation_restoration_test.dart`, `test/features/onboarding/onboarding_restoration_test.dart`, `test/features/profile/update_profile_restoration_test.dart` — each does `restartAndRestore` + builds with restoration disabled) and `test/app/state_restoration_test.dart` covers the observer + exclusions (splash-loop, dev-route, gate-route); **missing**: no end-to-end test seeds `nav.last_route` and asserts `createApplication` re-opens that route (the claimed integration bullet), and no explicit `restorationScopeId`-constant assertion. Blocking `done`.

## Risks / notes

- **Persisted settings already survive** via [`SettingsStore`](../../lib/features/settings/settings_store.dart) — restoration targets **only ephemeral UI state** (drafts, page index, scroll). Do not duplicate settings persistence into restoration properties.
- **`restorationScopeId` must be a constant** (`'app'`) and stable across releases; changing it invalidates every user's restorable state on upgrade.
- **Last-route vs. redirect precedence.** A saved last-route `initialLocation` must **not** override [onboarding-gate](onboarding-gate.md) (first launch still goes to onboarding) or [update-blocker](update-blocker.md) (a hard block still wins). Let the `go_router` redirect chain evaluate after `initialLocation` is set — do not fight it.
- **Golden re-baseline** is likely needed because `RestorationMixin` wraps the subtree; verify each restored page in the matrix on the pinned macOS runner.
- **Pairs with [lifecycle-observer](lifecycle-observer.md):** lifecycle-observer lands in the P0 foundation batch, state-restoration in P3 — the observer tells you when the app was backgrounded, restoration tells you what to bring back.
- Scope deliberately: restore the few stateful pages listed above — do not retrofit `RestorationMixin` onto every screen; the payoff does not justify the golden churn across the whole matrix.
