# Progress / busy indicators

> **Tier:** P1 · **Domain:** ux · **Backend:** none · **Status:** done · **Depends on:** none

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

- [x] No-backend honored as a port — **n/a**: backend-free; the overlay only mirrors in-flight presentation state (`busy_overlay.dart` reads `isBusy`), and the submit outcome still surfaces `notConnected` from each feature's state machine — no plugin calls anywhere in the widget.
- [x] Feature-first ownership — **pass**: `lib/shared/widgets/busy_indicator.dart` + `busy_overlay.dart`, peers of `escape_dismissible_overlay.dart`; no `core/`/`utils/` buckets introduced.
- [x] shared/widgets extraction ≥3 consumers — **pass**: concrete consumers are the five auth pages (`login_page.dart:162` mounts `BusyOverlay`; register/forgot/reset/otp likewise), `update_profile_page.dart:612` (`BusySeverity.saving`), `feedback_sheet.dart:219`, and `loading_state_view.dart` — well over three.
- [x] Composition root confined — **pass**: no providers or adapters introduced; pure widgets, nothing to wire in `AppDependencies`/`ProviderScope`.
- [x] Motion guarded — **pass**: `busy_overlay.dart:60-68` checks `MediaQuery.disableAnimationsOf` and falls back to a static localized label; `busy_overlay_test.dart:121,147` asserts the action still completes under reduce-motion; no navigation gates on the spinner; the feature's tests use bounded pumps, never `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: `common.saving` present in all three (`en.i18n.json:20`, `ar.i18n.json:20`, `zh-Hans.i18n.json:20`); `common.loading` pre-existing; generated `translations_*.g.dart` regenerated, not hand-edited.
- [x] Strict analysis clean — **pass**: typed `BusySeverity` enum with exhaustive switch (`busy_indicator.dart:45-49`), clamped determinate value, no `dynamic`/raw types in the new files.
- [x] Generated code untouched — **pass**: `*.g.dart` changes in the working tree correspond to source-JSON edits via `just gen` (no hand edits).
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: `busy.indeterminate` / `busy.determinate` / `busy.overlay` `PreviewFrame` cases committed (`busy_indicator_gallery_cases.dart`, registered in `gallery_registry.dart:33`); golden impact on the auth/profile submit matrix documented above — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (currently pending).
- [x] Port-reuse consistency — **n/a**: introduces no port; no parallel to `ConnectivityService`/`SecureStore` families.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart`, which gates on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the indicator mirrors in-flight state only; `BusyOverlay` blocks duplicate submits (`busy_overlay_test.dart:80`), and the action result is still the feature's own success/failure state — the widget never claims an outcome.

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
