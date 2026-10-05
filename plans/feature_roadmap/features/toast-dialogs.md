# Toast + confirmation-dialog wrappers

> **Tier:** P3 · **Domain:** ux · **Backend:** none · **Status:** done · **Depends on:** none

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

- [x] No-backend honored as a port — **n/a**: backend-free presentational wrappers over the mounted `FToaster`/`FDialog`; a no-backend action surfaces `notConnected` via `AppToast.show(severity: error)` (both banners do exactly this) — never a success toast for an action that did not succeed.
- [x] Feature-first ownership — **pass**: `lib/shared/widgets/feedback/{app_toast,app_confirmation_dialog}.dart` (plus `app_information_dialog.dart`, which absorbed the old `_showInformationDialog` pattern); peers of `escape_dismissible_overlay.dart`.
- [x] shared/widgets extraction ≥3 consumers — **pass**: `AppToast` has three concrete consumers (`announcements/announcement_banner.dart:43`, `connectivity/connectivity_banner.dart:44`, toast-dialogs gallery); `AppConfirmationDialog` has three (`auth/register_page.dart`, `profile/update_profile_page.dart`, gallery); `AppInformationDialog` additionally serves four route modules + `legal_dialog_callbacks.dart`. (Correction vs. the original audit line: `system_overlay_fixture.dart:146` still calls `showFToast` directly and never adopted `AppToast` — the wrapper's threshold is met without it; the un-subsumed fixture call site remains a consolidation TODO, not a threshold failure.)
- [x] Composition root confined — **pass**: no providers or adapters; pure helpers over the already-mounted `FToaster`; nothing to wire in `AppDependencies`/`ProviderScope`.
- [x] Motion guarded — **pass**: toast/dialog enter-exit is ForUI-native (`showFToast`/`showFDialog` animations); the dialog is wrapped in `EscapeDismissibleOverlay` (`app_confirmation_dialog.dart:43`) so Escape cancels without waiting on animation completion; `app_toast_test.dart:131` covers the reduce-motion path; feature tests never use `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: `common.confirm`/`success`/`discard`/`error` present in all three locales (`en.i18n.json:24-27`, `ar.i18n.json:24-27`, `zh-Hans.i18n.json:24-27`); localized-label behavior pinned in `app_toast_test.dart:13,25` and `app_confirmation_dialog_test.dart:20,77`.
- [x] Strict analysis clean — **pass**: typed `ToastSeverity` / `ConfirmationIntent` enums with exhaustive switches (`app_toast.dart:59-64,74-99`; `app_confirmation_dialog.dart:91-102`); no `dynamic`.
- [x] Generated code untouched — **pass**: no codegen for this feature; working-tree generated-file changes trace to source edits via `just gen`.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: committed per-severity + confirm/destroy `PreviewFrame` cases in `toast_dialogs_gallery_cases.dart`, registered in `gallery_registry.dart:51` — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (currently pending).
- [x] Port-reuse consistency — **pass**: wraps the existing `FToaster`/`FDialog` system (no `ScaffoldMessenger` fork); introduces no port.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: severity mapping never upgrades an outcome — `success` is caller-supplied only after a real success; `error`/`warning` carry `common.error` and destructive variants; confirmation returns a real `bool?` popped by explicit button or Escape, never an assumed confirm.

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
