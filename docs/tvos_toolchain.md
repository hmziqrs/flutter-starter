# tvOS toolchain

tvOS builds use the independent `flutter-tvos` distribution. Stock Flutter remains the authority
for Android, iOS, web, and desktop builds; never replace or upgrade the ordinary Flutter SDK when
working on tvOS.

## Exact pin

The machine-readable pin and engine checksums live in `tool/tvos/versions.env`:

- Tool tag: `v3.44.7-tvos.1.4.2`
- Tool commit: `aeedf41831c8bc2546afacbb7e686a4431ddb1d4`
- Flutter framework: `84fc5cbb223bc12f83d65b647ff8a56caf779ffd`
- Engine artifact release: `v1.0.1-flutter3.44.7`

Do not run `flutter-tvos upgrade`. Updating any value is a compatibility project requiring clean
Debug/Profile/Release builds, plugin and native-project drift review, simulator and device input
tests, and regenerated checksums.

## Install and verify

On macOS with Xcode, a tvOS simulator runtime, and CocoaPods:

```sh
tool/tvos/bootstrap.sh
tool/tvos/flutter-tvos.sh doctor -v
tool/tvos/verify_toolchain.sh
```

The default location is
`${XDG_CACHE_HOME:-$HOME/.cache}/flutter-tvos/v3.44.7-tvos.1.4.2`. Override it with
`FLUTTER_TVOS_HOME`. The wrapper refuses a different commit and never changes the stock Flutter
installation. Doctor can warn that the detached framework is on a user branch or that global
`flutter`/`dart` resolve elsewhere; those warnings are expected because isolation is intentional.
The dedicated tvOS validator, Xcode/tvOS SDK, CocoaPods, and engine-artifact checks must pass.

## Project generation

The committed `tvos/` target was produced by the pinned CLI, not copied from `ios/`:

```sh
flutter-tvos create --platforms=tvos \
  --project-name=starter --org=com.example <isolated-scaffold>
```

Only the generated `tvos/` directory was brought into the existing application. Developer-local
team identifiers were removed; signing is supplied by Xcode or CI configuration. The placeholder
bundle identifier `com.example.starter` must be replaced together with the Android identifier
before release.

## Dependencies and builds

Resolve and build only through the wrapper:

```sh
tool/tvos/flutter-tvos.sh pub get
tool/tvos/build_simulator.sh development
```

The two Flutter distributions share checkout-local `.dart_tool` and
`.flutter-plugins-dependencies` metadata. After any tvOS command, run stock
`flutter pub get` before a stock Flutter analyze, test, or build. The
`android-tv-build` recipe does this unconditionally so a preceding tvOS lane
cannot leak the fork's `integration_test` plugin path into an Android release
registrant.

The plugin lane is deliberately hybrid:

- `flutter_tvos 1.1.2`, `shared_preferences_tvos 0.0.2`, and
  `path_provider_tvos 0.0.3` ship
  `tvos/Package.swift` and are linked by the generated
  `FlutterGeneratedPluginSwiftPackage`.
- `package_info_plus_tvos 0.0.1` is podspec-only and is linked by CocoaPods.
- The Podfile skips packages owned by SwiftPM, preventing duplicate symbols.

Inspect `tvos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift`,
`tvos/Runner/GeneratedPluginRegistrant.m`, `tvos/Podfile.lock`, and the final app's merged privacy
manifests after every dependency change. Generated Flutter frameworks and ephemeral build files
remain ignored; `Podfile.lock` is regenerated during the clean experimental build lane.

Every app command must include `--dart-define-from-file=config/<environment>.json`. No signing
certificate, provisioning profile, API key, team ID, or secret belongs in the repository or those
JSON files.

## Release gates

Simulator compilation does not certify Siri Remote behavior, text entry, persistence across
relaunches, real-device AOT, signing, archive privacy reports, layered icon parallax, Top Shelf
presentation, screenshots, or App Store upload. Complete those checks on a physical Apple TV and
with developer-local/CI signing. tvOS can be removed from build orchestration without changing
other platform targets if the independent fork becomes incompatible.
