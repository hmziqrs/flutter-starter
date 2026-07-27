# Progress / busy indicators

> **Tier:** P1 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary

Standardized indeterminate + determinate progress plus an optional modal busy overlay that
blocks duplicate submits, so every async action looks identical. ForUI already ships the
primitives (`FCircularProgress` / `FDeterminateProgress`) — this is adoption plus one themed
wrapper, not a new dependency.

## Contract

- **Ports / value objects:** No port — backend-free. A `BusySeverity` enum
  (`none` / `active` / `saving`) or the existing per-feature async state drives display —
  auth pages' `*_PresentationStatus.submitting` (read via each page's `_submitting` getter)
  and profile's `_isSaving`.
  The overlay takes an optional semantics label and an optional determinate `value`
  (`0.0`–`1.0`; `null` = indeterminate).
- **Providers:** none — widgets read the feature's `*_presentation_state`.
- **Routes:** none.
- **Files:**
  - add `lib/shared/widgets/busy_indicator.dart` — themed `FCircularProgress` /
    `FDeterminateProgress` wrapper
  - add `lib/shared/widgets/busy_overlay.dart` — modal `Overlay` / `Dialog` entry; reduce-motion
    falls back to a static localized label
  - edit [`lib/features/profile/update_profile_page.dart`](../../lib/features/profile/update_profile_page.dart)
    — already uses `FCircularProgress` at line 509; adopt the wrapper there
  - edit `lib/features/auth/*_presentation_state.dart` + pages — replace the silent
    submit-button-disable with a visible indicator
  - add `test/shared/widgets/busy_indicator_test.dart`
  - add `PreviewFrame` cases (indeterminate / determinate / modal) to the dev gallery
- **Dependencies:** none (ForUI 0.24.1 ships `FCircularProgress` + `FDeterminateProgress`)

## Backend & test surface

Backend-free. The default impl is real and local — indicators reflect the async state
already in each feature's presentation-state machine: auth pages'
`*_PresentationStatus.submitting` (read via each page's `_submitting` getter) and profile's
`_isSaving` / `ProfilePresentationPhase.saving` (e.g. `update_profile_page`'s saving/saved).
No faked success: the indicator only mirrors in-flight
state; the action's outcome still surfaces `common.notConnected` when there is no backend.

## Tests

- **Unit/widget:** wrapper renders `FCircularProgress` with `semanticsLabel`; determinate
  variant clamps `value` to `[0,1]`; overlay blocks pointer events while mounted; reduce-motion
  path renders the static label and still completes.
- **Integration:** drive a submit through `createApplication` (in-memory, surfaces
  `notConnected`); `pumpAppFrames` asserts the overlay appears and dismisses — never
  `pumpAndSettle`.
- **Golden impact:** yes — auth/profile submit states change; add modal + inline `PreviewFrame`
  cases; re-baseline on the pinned macOS runner.
- **Dev-gallery fixture:** `PreviewFrame` cases for inline indeterminate, determinate at 60%,
  and the modal overlay, gated behind `developmentToolsEnabled`.

## i18n

- **Keys:** add `common.saving` ("Saving…"); `common.loading` already exists
  ([`en.i18n.json`](../../lib/i18n/en.i18n.json):19). Sync `common.saving` across `en` + `ar` +
  `zh-Hans`; run `just gen`.
- **RTL note:** n/a — radial spinner and a static centered label are direction-neutral.

## Audit

- [x] No-backend honored as a port — **n/a** (backend-free; reflects presentation-state flags; outcome still surfaces `notConnected`)
- [x] Feature-first ownership — **pass** (`lib/shared/widgets/`; peer of [`escape_dismissible_overlay.dart`](../../lib/shared/widgets/escape_dismissible_overlay.dart))
- [x] shared/widgets extraction ≥3 consumers — **pass** (login/register/forgot/reset/otp + profile = well over three async actions)
- [x] Motion guarded — **pass** (native indeterminate spinner; any custom pulse uses `AppMotion` + `disableAnimationsOf` + a non-animated fallback that completes the action)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (`common.saving` added to three locales)
- [x] Strict-analysis clean — **pass** (typed `BusySeverity` enum, exhaustive switch on the value state)
- [x] Native entitlements flagged — **n/a**
- [ ] Golden re-baseline noted on pinned macOS runner — **warn** (auth/profile submit-state matrix cases change)

## Risks / notes

- **Never gate navigation on the spinner.** Under reduce-motion and in test pumps the action
  must still call its `onResult` / `goNamed` — never wait on animation completion
  ([audit checklist #5](../contracts.md#5--motion-guarded)). Tests use `pumpAppFrames`.
- **Do not fork a progress primitive.** `FCircularProgress` / `FDeterminateProgress` are the
  ForUI primitives — [`update_profile_page.dart:509`](../../lib/features/profile/update_profile_page.dart)
  already proves the API. (Research noted "zero usages"; there is exactly one.) Do not introduce
  `ScaffoldMessenger` or a second progress dependency.
- **Pair with form-scaffolding.** The `FormScaffold` submit
  ([form-scaffolding.md](form-scaffolding.md)) should mount this indicator so the trio stays
  consistent — sequence after or alongside it.
