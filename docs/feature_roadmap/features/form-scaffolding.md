# Reusable form scaffolding

> **Tier:** P1 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary

Generalize the validators, password-toggle, and first-invalid-field-reveal already duplicated
across five auth pages into `lib/shared/forms/`, plus a `FormScaffold` widget — so future forms
(billing, settings-entry, feedback) don't re-implement validation. The seed already exists in
[`auth_form_support.dart`](../../lib/features/auth/auth_form_support.dart); this is an
extraction, not new behavior.

## Contract

- **Ports / value objects:** No port — backend-free. The existing `AuthInvalidFieldTarget`
  record moves verbatim and is renamed `InvalidFieldTarget`; validators keep their
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
  - edit [`lib/features/auth/auth_form_support.dart`](../../lib/features/auth/auth_form_support.dart)
    — becomes an aliasing facade (typedef + top-level aliases such as
    `final validateAuthRequired = validateRequired;`) so the five existing Auth-prefixed
    call sites resolve unchanged
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

- [x] No-backend honored as a port — **n/a** (backend-free; submit is feature-supplied and surfaces `notConnected`)
- [x] Feature-first ownership — **pass** (`lib/shared/forms/` + `lib/shared/widgets/forms/`; cross-feature helpers, no `core/`/`utils/`)
- [x] shared/widgets extraction ≥3 consumers — **split**: `lib/shared/forms/` helpers have 5
  current consumers (login/register/forgot/reset/otp — **pass**); `FormScaffold` is net-new
  with **0** concrete consumers and meets the bar via 3 designated consumers under D1
  (billing/settings/feedback), re-audited when those land.
- [x] Motion guarded — **pass** (`revealFirstInvalid` uses `Scrollable.ensureVisible`, not an animation; no motion to guard)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (no new keys)
- [x] Strict-analysis clean — **pass** (typed record, nullable `FormFieldState<Object?>`, no `dynamic`)
- [x] Native entitlements flagged — **n/a**
- [x] Golden re-baseline noted on pinned macOS runner — **warn** (validator/helper extraction stays covered by re-running the auth matrix; `FormScaffold` is net-new and needs its own `PreviewFrame` baseline)

## Risks / notes

- **Keep the facade.** Leave `auth_form_support.dart` as an aliasing facade (typedef + top-level
  aliases such as `final validateAuthRequired = validateRequired;`,
  `final validateAuthEmail = validateEmail;`, etc.) so the five existing Auth-prefixed call
  sites resolve unchanged — do not rewrite every auth page in this change. The extraction is
  rename-only; a pure Dart `export` cannot rename, so any behavior change is a separate PR.
- **Pair the submit with busy-indicators.** `FormScaffold` mounts the indicator from
  [busy-indicators.md](busy-indicators.md) so submit affordance is consistent — sequence after
  or alongside it.
- **No form codegen.** Handwritten `*_presentation_state` is the locked pattern
  ([architecture.md](../../architecture.md) state-settings). Do not introduce
  `flutter_form_builder` / `reactive_forms`.
