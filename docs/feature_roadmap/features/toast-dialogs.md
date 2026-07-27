# Toast + confirmation-dialog wrappers

> **Tier:** P3 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary

Thin ergonomic wrappers over the already-mounted `FToaster` and the existing `FDialog` /
`_showInformationDialog` pattern, pinning severity-to-style and localizing
`common.confirm` / `cancel` / `discard`. The capability exists and is correctly applied — this
is boilerplate reduction, not a new feature.

## Contract

- **Ports / value objects:** No port — backend-free. A `ToastSeverity` enum
  (`success` / `info` / `warning` / `error`) maps to `FToast` style; a `ConfirmationIntent` enum
  (`confirm` / `destroy`) maps to the `FButton` variant. Both take a localized title/body plus an
  optional action.
- **Providers:** none — pure helpers calling the mounted `FToaster` / `FDialog`.
- **Routes:** none.
- **Files:**
  - add `lib/shared/widgets/feedback/app_toast.dart` — `AppToast.show(context, severity, …)` →
    `showFToast` with pinned style and `common.success` / `common.error` titles
  - add `lib/shared/widgets/feedback/app_confirmation_dialog.dart` —
    `AppConfirmationDialog.show` with `confirm` = primary / `destroy` variants and localized
    `common.confirm` / `cancel` / `discard`, wrapped in `EscapeDismissibleOverlay`
  - edit `lib/i18n/{en,ar,zh-Hans}.i18n.json` — add generalized `common.confirm`,
    `common.success`, `common.discard`, `common.error` (currently only per-feature under
    `auth.*` / `profile.*`)
  - refactor the `_showInformationDialog` call sites in
    [`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart) — opportunistic,
    not required for the wrapper to ship
  - add `test/shared/widgets/feedback/app_toast_test.dart` +
    `app_confirmation_dialog_test.dart`
- **Dependencies:** none (ForUI `FToaster` / `FDialog` already mounted).

## Backend & test surface

Backend-free. The wrappers are pure presentational helpers over `FToaster` (mounted at
[`lib/app/app.dart`](../../lib/app/app.dart):121) and `FDialog`. A feature surfaces
`common.notConnected` for a no-backend action via `AppToast.show(severity: error, …)` or the
confirmation dialog — never a success toast for an action that did not succeed.

## Tests

- **Unit/widget:** `AppToast` maps each severity to the expected `FToast` variant + localized
  title; `AppConfirmationDialog` renders confirm/cancel (or destroy/discard) with the right
  `FButton` variants and localizes; Escape-to-cancel pops; the reduce-motion path still
  completes.
- **Integration:** surface a `notConnected` toast from a no-backend action via
  `createApplication` + `pumpAppFrames`; assert it appears and auto-dismisses.
- **Golden impact:** yes — toast/dialog severity variants are new `PreviewFrame` states;
  re-baseline on the pinned macOS runner. `system_overlay_fixture.dart` already renders some —
  extend it, don't fork.
- **Dev-gallery fixture:** `PreviewFrame` cases per severity + a confirm/destroy dialog, gated
  behind `developmentToolsEnabled` (consolidate with
  [`system_overlay_fixture.dart`](../../lib/features/dev_gallery/system/system_overlay_fixture.dart):147,
  which already uses `showFToast`).

## i18n

- **Keys:** `common.confirm`, `common.success`, `common.discard`, `common.error` — generalized
  (currently only per-feature). Synced across `en` + `ar` (RTL) + `zh-Hans`; run `just gen`.
- **RTL note:** toasts/dialogs center and mirror under `ar`; action-button order follows locale
  directionality — verify in the `PreviewFrame`.

## Audit

- [x] No-backend honored as a port — **n/a** (backend-free; `notConnected` surfaced via the error toast, never success for a no-backend action)
- [x] Feature-first ownership — **pass** (`lib/shared/widgets/feedback/`, peer of [`escape_dismissible_overlay.dart`](../../lib/shared/widgets/escape_dismissible_overlay.dart))
- [x] shared/widgets extraction ≥3 consumers — **pass** (verified consumers served by the proposed API: `register_page` discard → `destroy`, `update_profile_page` discard → `destroy`, `system_overlay_fixture` `showFToast` → toast, dev-gallery `PreviewFrame` fixtures = four. The `_showInformationDialog` call sites in `app_router.dart` are single-button informational dialogs the `ConfirmationIntent{confirm,destroy}` API cannot serve; that refactor stays in Files as opportunistic and is not counted toward the threshold.)
- [x] Motion guarded — **pass** (toast/dialog enter-exit is ForUI-native; any custom transition uses `AppMotion` + `disableAnimationsOf` + a fallback that completes the dismiss)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (`common.confirm` / `success` / `discard` / `error` added to three locales)
- [x] Strict-analysis clean — **pass** (typed `ToastSeverity` / `ConfirmationIntent` enums, exhaustive switch, no `dynamic`)
- [x] Native entitlements flagged — **n/a**
- [ ] Golden re-baseline noted on pinned macOS runner — **warn** (new toast/dialog severity matrix cases)

## Risks / notes

- **Do not introduce a second system.** `ScaffoldMessenger.SnackBar` fights the ForUI theme;
  `FToaster` is mounted at [`app.dart:121`](../../lib/app/app.dart) and `FDialog` is the
  established pattern. This feature wraps them — it does not replace them.
- **Consolidate, don't fork.** `showFToast` is already used in
  [`system_overlay_fixture.dart`](../../lib/features/dev_gallery/system/system_overlay_fixture.dart):147;
  the `AppToast` wrapper should subsume that call site, not add a parallel one.
- **Partly present.** Research flagged `alreadyPresent: true` for both toast and dialogs — keep
  scope tight to the two wrappers + the generalized `common.*` keys. Do not re-architect
  existing call sites beyond opportunistic adoption.
