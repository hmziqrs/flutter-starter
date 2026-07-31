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

Use Flutter 3.44.7 (Dart 3.12.x) and keep `pubspec.lock` committed.

- `just deps`: resolve locked dependencies.
- `just run macos`: launch with `config/development.json`; replace `macos` with
  another device target.
- `just gen`: regenerate Slang and other builder output.
- `just format-check && just analyze`: run the CI formatting and lint gates.
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
