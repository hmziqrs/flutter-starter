# Repository Guidelines

## Project Structure & Module Organization

Application code lives in `lib/` and follows feature-first ownership. Put product
screens and their typed view data under `lib/features/<feature>/`; shared adaptive,
motion, theme, and widget primitives belong in `lib/shared/`. Root composition,
routing, and configuration live in `lib/app/`, while logging, platform, and
preferences adapters live in `lib/infrastructure/`. Mirror source areas under
`test/`; desktop smoke coverage belongs in `integration_test/`. Fonts and other
bundled resources live in `assets/`. Read `docs/architecture.md` and
`plans/feature_roadmap/contracts.md` before changing public feature boundaries.
Routed features own their `*_routes.dart` registration modules and callback-to-navigation
wrappers; pages never import `go_router` or route constants. App-wide redirects and shell
composition stay under `lib/app/routing/`. Immutable model codegen uses committed Freezed
`*.freezed.dart`; Riverpod providers remain handwritten.

## Build, Test, and Development Commands

Use Flutter 3.44.7 (Dart 3.12.x) and keep `pubspec.lock` committed. GitHub
Actions builds release artifacts only, so run the quality gates locally before
pushing.

- `just deps`: resolve locked dependencies.
- `just run macos`: launch with `config/development.json`; replace `macos` with
  another device target.
- `just gen`: regenerate Slang and other builder output.
- `just format-check && just analyze`: run the formatting and lint gates.
- `just test`: run all non-golden unit and widget tests.
- `just test-goldens`: compare canonical goldens on the pinned macOS environment.
- `just smoke macos`: run the development integration flow.
- `just build apk`: create a production-configured release build for a target.

Run `just` to list all recipes.

## Coding Style & Naming Conventions

Follow `very_good_analysis` and `analysis_options.yaml`: two-space Dart
indentation, 100-column formatting, strict casts, inference, and raw types. Run
`dart format .` before committing. Name files `snake_case.dart`, types
`UpperCamelCase`, and members `lowerCamelCase`. Keep feature logic within its
owner; do not introduce generic `core/` or `utils/` buckets. Never edit generated
`*.g.dart`, `*.freezed.dart`, or ForUI theme files directly—change their sources and regenerate.

## Testing Guidelines

Tests use `flutter_test`; integration targets use Flutter's `integration_test`.
Name files `*_test.dart` and mirror the production path where practical. Add
widget and state coverage for behavioral changes, including responsive and
accessibility cases when UI is affected. Golden updates must be generated and
reviewed on the environment documented in `test/goldens/README.md`; inspect every
changed baseline image.

## Brand-parity hard rules

These rules exist because a full brand-port once converged "within ±2dp" on
every component while the real screens still looked nothing like the brand
site. Each rule below blocks one specific way that happened. They override
convenience and local green-checkmarks.

1. **Pages are verified against pages, never implied by components.** Component
   tests passing (even at ±2dp parity) never certify a screen or page. Any
   screen/page-level change is re-rendered headlessly and compared against the
   corresponding brand page reference (`build/brand-refs/pages/`) before it is
   called done. Whole-page fidelity (section order, composition, emotional
   register) is its own checklist item owned by a named reviewer — it is never
   a side effect of component work.
2. **Show renders, never summaries.** "Converged", "within tolerance", and
   "tests green" in text are not verification. At every convergence point the
   actual rendered PNG goes in front of the requester. A visual claim without a
   rendered image attached is unverified by definition.
3. **"Available" means visible in the app screens.** A brand surface (material
   card, glass panel, rings, signature footer) is not done when it exists in
   the dev gallery — it is done when a real screen uses it where the brand's
   own pages use it. Porting brand work ships the screen-level usage in the
   same pass; "we'll wire it into screens later" is an unfinished port.
4. **Restraint rules govern product chrome; showcase templates govern impact.**
   BRAND.md s4/s8/s13 restraint (outline cards, one orange action, material
   never behind body text) applies to product UI, but it must never be used to
   flatten a surface the brand renders boldly. When restraint and the showcase
   templates seem to conflict, match the corresponding brand page's actual
   composition — the pages are the authority on how bold the brand is.
5. **Measure numbers, compare images, show both.** Use the headless pipelines:
   `flutter test test/visual_dump_test.dart --update-goldens` renders every
   gallery case to `build/visual/` (real fonts, dark + light); brand truth
   photographs live in `build/brand-refs/` (storybook captures; regenerate by
   serving `brand-svelte/storybook-static` and screenshotting if wiped).
   Measure both sides with image scripts, then present the renders.
6. **No desktop input automation, ever.** Verification is headless only
   (widget-test renders, image scripts). Never post synthetic mouse/keyboard
   events to the user's desktop — it moves their cursor and steals focus while
   they work.
7. **Dead or silent subagents are the session's responsibility.** When a
   dispatched agent goes quiet without a report, check its files' mtimes and
   the render/test state, finish or repair its in-flight work, and reconcile
   it (compile, render test, overflow sweep) before reporting anything done.
   A half-landed agent is never allowed to count as "done".
8. **A stopped or superseded run's rules still apply.** Work inherited from a
   stopped workflow (uncommitted screen redesigns, mid-flight audits) is
   first-class: reconcile it, commit it, and include it in verification — do
   not silently redo it from scratch or leave it stranded uncommitted.

## Commits & Pull Requests

Recent history favors concise, imperative Conventional Commit subjects such as
`feat(ui): ...`, `test(integration): ...`, and `chore(config): ...`. Keep each
commit focused. Pull requests should explain behavior and architecture impact,
link relevant issues, include screenshots for visual changes, and list commands
run. Ensure formatting, analysis, generated-code drift, tests, and applicable
platform builds pass before review.

## Configuration & Security

Every launch/build must use `--dart-define-from-file=config/<environment>.json`.
These values are compiled into clients; never place secrets in configuration
files, logs, fixtures, or committed assets.
