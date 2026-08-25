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
package declares Flutter `>=3.44.0 <3.45.0` and Dart `>=3.12.0 <4.0.0`; using a
different Flutter patch is a reviewed toolchain change, not an incidental local
upgrade.

Current project deployment floors and validation targets are:

| Target | Project floor | CI build host/toolchain |
| --- | --- | --- |
| Android | API 24 (Flutter 3.44 template floor) | `ubuntu-24.04` x64, Temurin JDK 17, Android toolchain supplied by the runner/Flutter |
| iOS | iOS 13.0 | `macos-26` arm64, runner-default Xcode with Flutter Swift Package Manager integration, unsigned release build |
| macOS | macOS 10.15 | `macos-26` arm64, runner-default Xcode with Flutter Swift Package Manager integration |
| Windows | Windows 10/11 | `windows-2022` x64, Visual Studio 2022 with Desktop development with C++ |
| Linux | GTK 3 runtime | `ubuntu-24.04` x64 with Clang, CMake, Ninja, pkg-config, GTK 3 headers, and libstdc++ 12 headers |

Web remains optional and is not part of the release matrix. The runner labels
are specific supported GitHub-hosted runner families rather than floating
`*-latest` aliases. Review runner image changes, Xcode/Visual Studio changes,
and the action major versions in [`.github/workflows/release.yml`](.github/workflows/release.yml)
as maintenance changes.

GitHub Actions builds release artifacts only; quality gates (`just format-check`,
`just analyze`, `just test`, `just test-goldens`, and the integration flows) run
locally.

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
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
flutter test test
```

`flutter test test` includes canonical pixel comparisons and therefore should
only be treated as authoritative on the pinned macOS golden environment. On
other operating systems, run every non-golden test with:

```sh
find test -type f -name '*_test.dart' ! -path 'test/goldens/*' -print0 \
  | xargs -0 flutter test
```

CI performs the same separation: Ubuntu runs all non-golden unit, widget,
responsive, and accessibility tests; only `macos-26` compares the committed
pixels. This avoids cross-OS renderer differences without weakening functional
widget coverage.

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

Linux CI wraps both commands in `xvfb-run -a`. The development target covers a
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

Pull requests and pushes to `main` run:

- Ubuntu 24.04: formatting, fatal analysis, generated drift, every non-golden
  unit/widget/accessibility test, both Linux integration targets under Xvfb,
  and Android/Linux production release builds.
- macOS 26 arm64: the canonical golden comparison plus unsigned iOS and macOS
  production release builds.
- Windows Server 2022: the Windows production release build.

The workflow pins Flutter 3.44.7, `actions/checkout@v6`,
`actions/setup-java@v5`, and `subosito/flutter-action@v2`. GitHub-hosted runners
satisfy the Node 24 action-runtime requirement; any future self-hosted runner
must use Actions Runner 2.329.0 or newer before these action lines are reused
(`checkout@v6` has the highest runner requirement in this workflow).

## Dependency maintenance

Keep `pubspec.lock` committed. Review upgrades deliberately, especially ForUI
pre-1.0 changes and major updates to Flutter, Riverpod, Slang, ExUI, and Simple
Animations:

```sh
flutter pub outdated
flutter pub upgrade
flutter pub upgrade forui --major-versions
dart fix --dry-run
flutter analyze --fatal-infos
flutter test test
```

Read the relevant changelogs and inspect `dart fix --dry-run` before applying
any fix. After an accepted dependency change, regenerate committed output and
run the full platform build matrix. Never apply an automated dependency or
source rewrite blindly.

Primary infrastructure references:

- [GitHub-hosted runner labels](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Flutter Linux prerequisites](https://docs.flutter.dev/platform-integration/linux/setup)
- [Flutter Action setup and caching](https://github.com/marketplace/actions/flutter-action)
