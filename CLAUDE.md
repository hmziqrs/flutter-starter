# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The two imported files below are the authoritative guidance — read them before making changes.
`docs/architecture.md` is a subsystem index (per-concern "start here" files, add-a-screen/setting/feature
recipes, guardrails); `AGENTS.md` covers project structure, style, testing, and commit conventions.
Consult `plans/feature_contracts.md` before changing any feature's public API.

@AGENTS.md
@docs/architecture.md

## Command quick reference

Toolchain is pinned: Flutter 3.44.7 / Dart 3.12.x. `just` with no args lists all recipes.

- `just deps` — resolve locked dependencies
- `just run macos` — run the app with dev config (replace `macos` with any device target)
- `just gen` — regenerate slang/build_runner output (commit the generated files)
- `just format-check && just analyze` — CI formatting and lint gates (`--fatal-infos`)
- `just test` — all non-golden unit/widget tests
- `flutter test test/path/to/file_test.dart` — run a single (non-golden) test file; add
  `--plain-name "test name"` to filter to one test
- `just test-goldens` — golden comparison; authoritative only on the pinned macOS environment
  (`test/goldens/README.md`). Regenerate baselines with
  `flutter test test/goldens/canonical_matrix_golden_test.dart --update-goldens`
- `just smoke macos` — dev integration smoke, headless CI mode; `just watch [dilation] [device]`
  runs it visibly with slowed animations
- `just test-prod-routes macos` — proves dev routes are absent under the production config
- `just build <target>` — production release build (`apk`, `appbundle`, `ios`, `macos`, `linux`,
  `windows`, `web`)

Gotchas:

- Every app launch, release build, and integration test requires
  `--dart-define-from-file=config/<env>.json` (the `just` recipes pass it); without it startup
  throws `AppEnvironmentException`. Unit/widget tests are exempt — they build config through
  `AppConfig.fromValues`.
- After editing `lib/i18n/*.i18n.json` or other codegen sources, run `just gen` and commit all
  generated output together; CI enforces zero drift via `just gen-check`.
