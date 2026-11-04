# Compact cross-platform Flutter starter

A feature-first Flutter baseline for Android, iOS, macOS, Windows, and Linux.
It provides explicit compile-time environments, ForUI, Riverpod, `go_router`,
Slang localization, adaptive layouts, persisted settings, deterministic static
screen states, a development gallery, and a multi-platform verification suite.

The architecture decisions live in [`plans/completed/initial.md`](plans/completed/initial.md), the
static UI contract in [`plans/completed/initial_ui.md`](plans/completed/initial_ui.md), and the
execution sequence in
[`plans/completed/implementation_workflow.md`](plans/completed/implementation_workflow.md).
The post-implementation abstraction decisions are summarized in
[`docs/baseline_architecture_report.md`](docs/baseline_architecture_report.md).
The subsystem index — the per-concern "start here" map of the codebase — is
[`docs/architecture.md`](docs/architecture.md).

## Supported SDK and targets

CI uses Flutter **3.44.7 stable** exactly, which bundles Dart **3.12.2**. The
package declares Flutter `>=3.44.0 <4.0.0` and Dart `^3.12.0`, and `mise.toml`
pins the exact SDK; using a different Flutter patch is a reviewed toolchain
change, not an incidental local upgrade. Every `just` recipe runs through mise
when it is installed, so the pin holds even if another SDK is first on `PATH`.

Current project deployment floors and validation targets are:

| Target | Project floor | CI build host/toolchain |
| --- | --- | --- |
| Android | API 26 | `ubuntu-24.04` x64, Temurin JDK 17, Android toolchain supplied by the runner/Flutter |
| iOS | iOS 15.0 | `macos-26` arm64, runner-default Xcode with Flutter Swift Package Manager integration, unsigned release build |
| macOS | macOS 12.0 | `macos-26` arm64, runner-default Xcode with Flutter Swift Package Manager integration |
| Windows | Windows 10/11 | `windows-2022` x64, Visual Studio 2022 with Desktop development with C++ |
| Linux | GTK 3 runtime | `ubuntu-24.04` x64 with Clang, CMake, Ninja, pkg-config, GTK 3 headers, and libstdc++ 12 headers |

Xcode 27 cannot produce a universal macOS build with this Flutter: its `lipo`
rejects the multi-architecture check Flutter runs. `just build macos` detects it
and builds the host architecture instead, and CI's Xcode 26 still produces the
universal app.

Web remains optional and is not part of the release matrix. The runner labels
are specific supported GitHub-hosted runner families rather than floating
`*-latest` aliases. Review runner image changes, Xcode/Visual Studio changes,
and the action major versions in [`.github/workflows/release.yml`](.github/workflows/release.yml)
as maintenance changes.

GitHub Actions builds release artifacts only; quality gates (`just format-check`,
`just analyze`, `just test`, `just test-goldens`, and the integration flows) run
locally.

## Make it yours

Three commands turn the starter into your app. The first is a dry run until you
add `apply`:

```sh
just rename "Sightline" com.acme.sightline apply
just gen
just brand-assets Si Sightline
```

`just rename` changes the display name, bundle and application ids, and the
Android package on every platform (`tool/rename_app.py --dart-package` also
renames the Dart package). `just brand-assets` redraws every launcher icon, TV
banner, Top Shelf image and splash logo from the brand's Mark recipe, using your
two-letter symbol, then rebuilds the native launch screens.

## Brand

Theme and components are a Flutter port of the hmziq brand kit. Tokens live in
`lib/shared/theme/`, and the kit's pieces in `lib/shared/widgets/` (`blocks`,
`brand`, `glass`, `marks`, `rings`) and `lib/shared/fx/`. Run a development build
and open **Brand gallery** in the sidebar to see every piece, and `/dev/screens`
at any viewport, mode and locale.

Check visual work headlessly; neither command touches your desktop:

```sh
just visual          # every gallery case, phone and desktop, dark and light
just visual-screens  # the real app on every route at phone, tablet and desktop
```

Renders land in `build/visual/` and `build/visual-screens/`, each with a
`_report.txt` listing any layout exception. `AGENTS.md` has the brand-parity
rules these support.

## Set up and run

Install Flutter 3.44.7, confirm the bundled Dart version, and resolve the locked
application dependencies:

```sh
flutter --version
flutter pub get
```

Every application launch must select an explicit non-secret compile-time
configuration:

```sh
flutter run --dart-define-from-file=config/development.json
flutter run --dart-define-from-file=config/staging.json
flutter run --dart-define-from-file=config/production.json
```

Development enables verbose local logging and the `/dev/screens` and
`/dev/diagnostics` routes. Staging and production disable those routes. The
JSON files are compiled into the client and must never contain secrets.

## Code generation and local checks

Slang output and any other builder output are committed. Regenerate them with:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Before opening a pull request, run:

```sh
just format-check
just analyze
just gen-check
just test
just test-goldens
```

`just gen-check` fails on uncommitted changes, so run it from a clean tree.
`just test` skips the canonical pixel comparisons and the visual tools, and runs
on any operating system.

## Golden review

The 13-case pairwise matrix, source-controlled fonts, renderer, device-pixel
ratio, and settled animation timestamp are documented in
[`test/goldens/README.md`](test/goldens/README.md). Review or update snapshots
only on that environment:

```sh
flutter test test/goldens/canonical_matrix_golden_test.dart --update-goldens
flutter test test/goldens/canonical_matrix_golden_test.dart
git diff -- test/goldens/baselines
```

Inspect every changed image at full size. Do not accept a bulk update, switch
host operating systems, or add a broad pixel tolerance merely to make a diff
pass.

## Integration smoke tests

The desktop smoke targets exercise the real application composition. Each one
requires its matching explicit environment:

```sh
flutter test integration_test/development_smoke_test.dart \
  -d linux \
  --dart-define-from-file=config/development.json

flutter test integration_test/production_routes_test.dart \
  -d linux \
  --dart-define-from-file=config/production.json
```

On a headless Linux host, wrap both commands in `xvfb-run -a`. The development target covers a
representative local-only flow, settings persistence, locale/theme changes,
and resizing. The independent production target proves that development routes
are not registered. Android/iOS device runs or Patrol belong here only after a
real native workflow requires them.

## Release build commands

Release builds never infer or default the environment:

```sh
flutter build apk --release \
  --dart-define-from-file=config/production.json
flutter build linux --release \
  --dart-define-from-file=config/production.json
flutter build ios --release --no-codesign \
  --dart-define-from-file=config/production.json
flutter build macos --release \
  --dart-define-from-file=config/production.json
flutter build windows --release \
  --dart-define-from-file=config/production.json
```

These commands verify compilation only; they do not produce signed or
store-ready artifacts. Complete [`docs/release_readiness.md`](docs/release_readiness.md)
before public distribution.

## CI architecture

GitHub Actions builds release artifacts only (`.github/workflows/release.yml`),
on pushes to `master` and on demand: macOS universal and iOS on `macos-26`,
Windows x64, Linux x64 and arm64, and Android APKs and App Bundle. Quality gates
run locally, as listed above. Signing is deferred, so artifacts are unsigned or
debug-signed; see `docs/release_readiness.md`.

`.github/workflows/regenerate-goldens.yml` regenerates the canonical baselines
on the `macos-26` runner and opens a pull request for review.

## Dependency maintenance

Keep `pubspec.lock` committed. Review upgrades deliberately, especially ForUI
pre-1.0 changes and major updates to Flutter, Riverpod, Slang, ExUI, and Simple
Animations:

```sh
flutter pub outdated
flutter pub upgrade
flutter pub upgrade forui --major-versions
dart fix --dry-run
just analyze
just test
```

Read the relevant changelogs and inspect `dart fix --dry-run` before applying
any fix. After an accepted dependency change, regenerate committed output and
run the full platform build matrix. Never apply an automated dependency or
source rewrite blindly.

Primary infrastructure references:

- [GitHub-hosted runner labels](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Flutter Linux prerequisites](https://docs.flutter.dev/platform-integration/linux/setup)
- [Flutter Action setup and caching](https://github.com/marketplace/actions/flutter-action)
