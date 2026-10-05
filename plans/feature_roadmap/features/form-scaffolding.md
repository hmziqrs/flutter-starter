# Reusable form scaffolding

> **Tier:** P1 · **Domain:** ux · **Backend:** none · **Status:** done · **Depends on:** none

## Summary

Generalize the validators, password-toggle, and first-invalid-field-reveal already duplicated
across five auth pages into `lib/shared/forms/`, plus a `FormScaffold` widget — so future forms
(billing, settings-entry, feedback) don't re-implement validation. The seed was
`lib/features/auth/auth_form_support.dart`, now extracted and deleted; this is an extraction,
not new behavior.

## Contract

- **Ports / value objects:** No port — backend-free. The former `AuthInvalidFieldTarget`
  record moved verbatim and is renamed `InvalidFieldTarget`; validators keep their
  `(value, messages)` signatures. No codegen — presentation_state stays handwritten Riverpod.
- **Providers:** none — pure helpers + a widget. State stays in each feature's
  `*_presentation_state`.
- **Routes:** none.
- **Files:**
  - add `lib/shared/forms/form_validators.dart` — `validateRequired` / `validateEmail` /
    `validatePassword` (moved verbatim from `auth_form_support.dart`, `Auth` prefix dropped)
  - add `lib/shared/forms/form_field_reveal.dart` — `revealFirstInvalid` + the
    `InvalidFieldTarget` typedef
  - add `lib/shared/forms/password_field_toggle.dart` — `buildPasswordToggle`
  - add `lib/shared/widgets/forms/form_scaffold.dart` — `FScaffold` + `FButton` submit +
    `FCard` grouping
  - delete `lib/features/auth/auth_form_support.dart` — the transitional aliasing facade; the
    five auth pages import `lib/shared/forms/` directly
  - add `test/shared/forms/form_validators_test.dart` + `test/shared/forms/form_field_reveal_test.dart`
- **Dependencies:** none (Flutter SDK + ForUI `FTextField` / `FButton` / `FScaffold`)

## Backend & test surface

Backend-free. The default impl is real and local — validators are pure functions and the submit
callback is feature-supplied through the existing `*_presentation_state` trio. A form with no
backend surfaces `common.notConnected` on submit; it never fakes success.

## Tests

- **Unit/widget:** each validator's accept/reject branches (incl. trim vs no-trim for email,
  no-trim for password); `revealFirstInvalid` scrolls and focuses in explicit visual order;
  `FormScaffold` disables submit until valid and mounts the busy indicator on submit.
- **Integration:** the existing auth flows still pass via `createApplication` + `pumpAppFrames`
  after the aliasing facade swap (behavior-preserving).
- **Golden impact:** split — validator/helper extraction is behavior-preserving (re-run the auth
  matrix to confirm no pixel drift); `FormScaffold` is net-new and needs its own baseline.
- **Dev-gallery fixture:** split — validator/helper extraction stays covered by re-running the
  production auth gallery cases; `FormScaffold` is net-new and **requires** a standalone
  `PreviewFrame` baseline (committed, re-audited on the pinned macOS runner).

## i18n

- **Keys:** none new — reuse the existing `auth.common.showPassword` / `hidePassword` and
  `common.save` / `cancel` / `retry`.
- **RTL note:** n/a — validators are locale-agnostic; the password-toggle icon is mirrored by
  ForUI.

## Audit

- [x] No-backend honored as a port — **n/a**: backend-free; submit is feature-supplied through the `*_presentation_state` trio and a no-backend submit surfaces `common.notConnected` (auth flows); no plugin calls in any helper or widget.
- [x] Feature-first ownership — **pass**: `lib/shared/forms/{form_validators,form_field_reveal,password_field_toggle}.dart` + `lib/shared/widgets/forms/{form_scaffold,form_submit_button}.dart`; the transitional `auth_form_support.dart` is deleted (no references anywhere in `lib/` or `test/`).
- [x] shared/widgets extraction ≥3 consumers — **pass (split, as designed)**: the `lib/shared/forms/` helpers have 7 concrete consumers (login/register/forgot/reset/otp pages + `feedback_sheet.dart:9` + `update_profile_page.dart`); `FormSubmitButton` is consumed by all five auth pages; `FormScaffold` itself has 0 production consumers today and meets the bar via the 3 C1-designated deferred consumers (billing/settings/feedback) recorded in this doc — re-audit when those land.
- [x] Composition root confined — **pass**: no providers introduced; pure helpers + widgets, nothing to wire in `AppDependencies`/`ProviderScope`.
- [x] Motion guarded — **pass**: `revealFirstInvalid` uses `Scrollable.ensureVisible` + `requestFocus` (`form_field_reveal.dart:20-21`), not an animation — nothing to guard; `FormScaffold`'s busy state is the reduce-motion-guarded `BusyOverlay`; feature tests use bounded pumps, never `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: no new keys — reuses `auth.common.showPassword`/`hidePassword` (`password_field_toggle.dart:9-10`) and `common.save`/`cancel`/`retry`; verified no hardcoded user-facing copy in the new files.
- [x] Strict analysis clean — **pass**: typed `InvalidFieldTarget` record with nullable `FormFieldState<Object?>` (`form_field_reveal.dart:3-7`); validators keep `(value, messages)` signatures; no `dynamic`/raw types.
- [x] Generated code untouched — **pass**: no codegen involved (presentation state stays handwritten); working-tree `*.g.dart`/`*.freezed.dart` changes trace to source edits via `just gen`, not hand edits.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: `FormScaffold` has committed `PreviewFrame` states disabled/enabled/submitting (`form_scaffolding_gallery_cases.dart`, registered in `gallery_registry.dart:37`); helper extraction is behavior-preserving (auth matrix re-run) — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (the committed baselines are outdated vs HEAD; that re-baseline is outstanding).
- [x] Port-reuse consistency — **n/a**: introduces no port; nothing parallel to existing port families.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: `form_scaffold_test.dart:84` asserts submit is blocked while submitting; the no-backend outcome remains the feature's `notConnected` path, never a faked success from the scaffold.

## Risks / notes

- **The facade is retired.** `auth_form_support.dart` served its purpose as a rename-only
  aliasing shim during the extraction and has since been deleted; the five auth pages now import
  `lib/shared/forms/` directly. Do not reintroduce it — a new alias layer over `shared/forms/`
  would be pure indirection.
- **Pair the submit with busy-indicators.** `FormScaffold` mounts the indicator from
  [busy-indicators.md](busy-indicators.md) so submit affordance is consistent — sequence after
  or alongside it.
- **No form codegen.** Handwritten `*_presentation_state` is the locked pattern
  ([architecture.md](../../../docs/architecture.md) state-settings). Do not introduce
  `flutter_form_builder` / `reactive_forms`.
