# Baseline architecture report

This report records the abstraction review performed after implementing the compact static
baseline. It is deliberately about the code that exists now; deferred product capabilities remain
decisions, not empty interfaces or fake services.

## Kept

- **Feature-first source ownership.** Auth, onboarding, pricing, home, profile, and settings own
  their pages, typed values, validators, and deterministic presentation fixtures.
- **Root composition.** `app/dependencies.dart`, `app/routing/app_router.dart`, and `bootstrap.dart`
  remain the only places that construct concrete adapters, compose cross-feature navigation, and
  create the production application graph.
- **Handwritten settings boundary.** `SettingsStore`, `SettingsRepository`, and
  `SettingsController` are small enough to remain handwritten. The in-memory store serves tests;
  `SharedPreferencesSettingsStore` is the sole production preferences adapter.
- **ForUI theme tokens and controls.** ForUI owns styled application controls. The generated theme
  colors, typography, icons, and base style stay source controlled; empty generated theme-extension
  placeholders were removed because they had no callers.
- **Shared adaptive and motion policy.** The canonical layout classes, interaction policy, gallery
  environment, spacing/sizing tokens, and motion tokens have multiple production or verification
  callers and remain shared.
- **Generated Slang localization.** English, Arabic, and Simplified Chinese sources generate the
  type-safe application localization surface; no wrapper or second localization system was added.

## Changed after real callers

- Login and Register were implemented before reviewing form duplication. Their common
  first-error reveal and field-border behavior earned the small auth-owned support module;
  feature-specific validation, focus nodes, controls, and typed submission values stayed in each
  page. No project-wide form abstraction was justified.
- Escape dismissal was repeated across application dialogs, gallery overlays, and recovery
  surfaces, so it earned one shared `EscapeDismissibleOverlay` wrapper.
- Integration tests needed the same production dependency and startup composition as `main.dart`,
  so bootstrap exposes `createApplication` while `bootstrap` retains error-handler installation and
  the final `runApp` boundary.
- Settings persistence keys became an explicit public allowlist so integration cleanup removes only
  starter-owned values and never clears unrelated platform preferences.
- ExUI earned one direct, single-operation, token-based shell padding caller. No Material or
  Cupertino ExUI library, broad re-export, styling helper, or interaction wrapper was introduced.
- The dark destructive/error foreground token was adjusted after exhaustive numerical contrast
  tests; the decision lives in the root theme factory rather than per-screen overrides.

## Rejected or deferred

- Generic `core/`, `utils/`, service-locator, use-case, base-repository, base-page, and feature-barrel
  layers were rejected because the implemented callers do not need them.
- Dartx, Riverpod code generation, Mocktail, a second form engine, a second component system, and a
  second localization or dependency-injection framework were not installed.
- Fake auth, OTP, purchase, restore, upload, network, database, secure-storage, telemetry, audio,
  download, and notification services were rejected. Static callbacks provide honest local
  navigation or unavailable feedback without claiming backend success.
- Flutter restoration and operating-system link registration remain disabled until their product
  identifiers, privacy policy, sensitive-field allowlist, and platform associations are defined.
- Signing, final identifiers, brand assets, telemetry/consent, real backend contracts, native
  workflows, store delivery, and device/screen-reader sign-off remain release work. Owners and
  required evidence are listed in [release readiness](release_readiness.md).

## Result

The baseline has only abstractions with current production or verification callers. New product
work should add a capability at its first real boundary, then revisit this report only when the
resulting repeated code proves a smaller shared contract.
