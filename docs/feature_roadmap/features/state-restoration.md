# State restoration + last-screen persistence

> **Tier:** P3 · **Domain:** startup · **Backend:** none · **Status:** planned · **Depends on:** [lifecycle-observer](lifecycle-observer.md) (pairs naturally)

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

- [x] No-backend honored as a port — **pass**: backend-free; reuses `SettingsStore` for last-route only.
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: edits are feature-local plus one `app.dart` line.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**.
- [x] Motion guarded — **n/a**.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**.
- [x] Strict-analysis clean — **pass**: typed restoration properties, no `dynamic`.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Golden re-baseline noted on pinned macOS runner — **warn**: `RestorationMixin` wrapper may require re-baseline.

## Risks / notes

- **Persisted settings already survive** via [`SettingsStore`](../../lib/features/settings/settings_store.dart) — restoration targets **only ephemeral UI state** (drafts, page index, scroll). Do not duplicate settings persistence into restoration properties.
- **`restorationScopeId` must be a constant** (`'app'`) and stable across releases; changing it invalidates every user's restorable state on upgrade.
- **Last-route vs. redirect precedence.** A saved last-route `initialLocation` must **not** override [onboarding-gate](onboarding-gate.md) (first launch still goes to onboarding) or [update-blocker](update-blocker.md) (a hard block still wins). Let the `go_router` redirect chain evaluate after `initialLocation` is set — do not fight it.
- **Golden re-baseline** is likely needed because `RestorationMixin` wraps the subtree; verify each restored page in the matrix on the pinned macOS runner.
- **Pairs with [lifecycle-observer](lifecycle-observer.md):** the observer tells you *when* the app was backgrounded; restoration tells you *what* to bring back. They are independent but sequenced together in the [P3 batch](../README.md#sequencing).
- Scope deliberately: restore the few stateful pages listed above — do not retrofit `RestorationMixin` onto every screen; the payoff does not justify the golden churn across the whole matrix.
