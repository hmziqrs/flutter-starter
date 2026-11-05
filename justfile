# Flutter starter — common dev tasks. Run `just` (no args) to list recipes.
#
# Integration tests have two modes:
#   just smoke   → headless "coverage" mode (pins phone/tablet/desktop
#                  sizes; the macOS window shows "Test starting...", which is expected)
#   just watch   → visible mode: real window, slowed animations, step pauses

dev_config  := "config/development.json"
prod_config := "config/production.json"
# Run through mise when available so every recipe uses the Flutter SDK pinned
# in mise.toml (matching the pubspec.yaml constraint) instead of whatever
# `flutter` is first on PATH; environments without mise keep using PATH.
flutter     := `command -v mise >/dev/null 2>&1 && echo 'mise exec -- flutter' || echo 'flutter'`
dart        := `command -v mise >/dev/null 2>&1 && echo 'mise exec -- dart' || echo 'dart'`

# List available recipes.
default:
    @just --list --unsorted

# --- setup --------------------------------------------------------------------
# Resolve dependencies.
deps:
    {{flutter}} pub get

# Regenerate slang translations and other build_runner outputs.
gen:
    {{dart}} run build_runner clean
    rm -f lib/i18n/translations.g.dart lib/i18n/translations_en.g.dart lib/i18n/translations_ar.g.dart lib/i18n/translations_zh_Hans.g.dart
    {{dart}} run build_runner build

# Remove all build artifacts.
clean:
    {{flutter}} clean

# --- quality ------------------------------------------------------------------
# Static analysis (--fatal-infos: infos fail the gate).
analyze:
    {{flutter}} analyze --fatal-infos

# Format the codebase in place.
format:
    {{dart}} format lib test integration_test

# Fail if anything is unformatted (pre-commit gate).
format-check:
    {{dart}} format --output=none --set-exit-if-changed lib test integration_test

# Verify generated code is committed and in sync (pre-commit gate).
gen-check:
    {{dart}} run build_runner clean
    rm -f lib/i18n/translations.g.dart lib/i18n/translations_en.g.dart lib/i18n/translations_ar.g.dart lib/i18n/translations_zh_Hans.g.dart
    {{dart}} run build_runner build
    git diff --exit-code

# Rename the starter into your own app on every platform. Dry run unless apply
# is passed: just rename "Sightline" com.acme.sightline apply
rename name id apply='':
    python3 tool/rename_app.py --name '{{name}}' --id '{{id}}' {{ if apply == 'apply' { '--apply' } else { '' } }}

# --- brand assets --------------------------------------------------------------
# Redraw every launcher icon, TV banner and splash logo from the brand's Mark
# recipe, then bake the logos into the native launch screens.
#   just brand-assets St Starter
brand-assets symbol='St' name='Starter':
    {{flutter}} test tool/brand_assets/generate_brand_assets_test.dart \
        --dart-define=WRITE_BRAND_ASSETS=true \
        '--dart-define=BRAND_SYMBOL={{symbol}}' \
        '--dart-define=BRAND_NAME={{name}}'
    {{dart}} run flutter_native_splash:create

# --- native splash (codegen; config in flutter_native_splash.yaml) ------------
# Regenerate the committed native launch assets (iOS storyboard, Android
# drawable + Android-12 styles, web splash). Mirrors `gen`/`gen-check`: review
# the committed native diff before accepting the CLI output.
splash:
    {{dart}} run flutter_native_splash:create

# Remove the generated native splash launch assets (undo `splash`).
splash-remove:
    {{dart}} run flutter_native_splash:remove

# --- run the app (development config) -----------------------------------------
# Run on a device (default macos): just run [chrome|macos|ios|<device-id>]
run dev='macos':
    #!/usr/bin/env bash
    set -euo pipefail

    device='{{dev}}'
    if [[ "$device" == 'ios' ]]; then
        if ! command -v xcrun >/dev/null 2>&1; then
            echo 'The ios shortcut requires Xcode command-line tools.' >&2
            exit 1
        fi

        device="$(
            xcrun simctl list devices available |
                sed -nE '/(iPhone|iPad)/s/.*\(([0-9A-Fa-f-]{36})\) \(Booted\).*/\1/p' |
                head -n 1
        )"

        if [[ -z "$device" ]]; then
            device="$(
                xcrun simctl list devices available |
                    sed -nE '/iPhone/s/.*\(([0-9A-Fa-f-]{36})\) \(Shutdown\).*/\1/p' |
                    head -n 1
            )"
            if [[ -z "$device" ]]; then
                echo 'No available iPhone simulator was found. Install one in Xcode.' >&2
                exit 1
            fi

            xcrun simctl boot "$device"
            open -a Simulator
        fi
    fi

    exec {{flutter}} run -d "$device" --target=lib/main_dev.dart --dart-define-from-file={{dev_config}}

# Run the app wired to the in-repo dummy backend (start it first with
# `just backend`). BACKEND_BASE_URL is injected via --dart-define over the
# zero-backend development.json (the same merge the smoke flow uses), so no
# separate config file is needed. host defaults to loopback; pass 10.0.2.2 for
# the Android emulator (its alias for host loopback).
run-backend dev='macos' host='127.0.0.1':
    {{flutter}} run -d {{dev}} --target=lib/main_dev.dart \
        --dart-define-from-file={{dev_config}} \
        --dart-define=BACKEND_BASE_URL=http://{{host}}:8080

# --- tests --------------------------------------------------------------------
# All non-golden unit + widget tests (the main quality gate).
# Full output goes to build/test.log; stdout carries only the verdict so gate
# runners with small log caps don't drown in per-test progress lines. On
# failure it dumps the log minus passing-test progress lines (capped).
test:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p build
    log=build/test.log
    if {{flutter}} test $(find test -type f -name '*_test.dart' ! -path 'test/goldens/*' ! -path 'test/visual/*') >"$log"; then
        tail -n 1 "$log"
    else
        status=$?
        echo "Tests failed (exit $status). Full log: $log"
        awk '!(/^[0-9][0-9]:[0-9][0-9] \+[0-9]+: / && $0 !~ /\[E\]/)' "$log" |
            tail -c 250000 || true
        exit "$status"
    fi

# Canonical golden baseline (run on macOS; see test/goldens/README.md).
# Pixels are exact only on the macOS 26 reference. Other macOS versions anti-alias
# a few edge pixels differently, so a failure there is reported as advice, and
# `just goldens-ci` gives the real verdict.
test-goldens:
    #!/usr/bin/env bash
    set -uo pipefail
    {{flutter}} test test/goldens/canonical_matrix_golden_test.dart
    status=$?
    major="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
    if [[ "$status" -ne 0 && "$major" != '26' ]]; then
        echo "Goldens differ on macOS ${major:-unknown}; the baselines are exact on macOS 26 only." >&2
        echo "Run 'just goldens-ci' for the authoritative comparison." >&2
        exit 0
    fi
    exit "$status"

# Compare on the macOS 26 runner. The run's summary says whether baselines already
# matched; if not, it pushes goldens/regen-N for review. Push your branch first.
goldens-ci:
    gh workflow run regenerate-goldens.yml --ref "$(git branch --show-current)"

# Render every gallery case at phone and desktop sizes (dark + light) to
# build/visual/. Headless; never touches the desktop. See AGENTS.md rule 5.
visual:
    {{flutter}} test test/visual/gallery_dump_test.dart --update-goldens
    {{flutter}} test test/visual/gallery_dump_test.dart --update-goldens --dart-define=VISUAL_VIEWPORT=desktop

# Render the real app on every route at phone, tablet and desktop sizes (dark +
# light) to build/visual-screens/. Headless. This is what proves a screen.
visual-screens:
    {{flutter}} test test/visual/app_screens_test.dart --update-goldens

# Dev smoke integration test — HEADLESS coverage mode.
# Asserts the full flow + persistence across compact/medium/expanded layouts.
smoke dev='macos':
    {{flutter}} test integration_test/development_smoke_test.dart -d {{dev}} --dart-define-from-file={{dev_config}}

# Injected ten-foot remote-only integration flow.
smoke-tv dev='macos':
    {{flutter}} test integration_test/tv_remote_smoke_test.dart -d {{dev}} --dart-define-from-file={{dev_config}}

# Dev smoke integration test — VISIBLE watch mode (real window, slowed animations).
#   just watch        # 2x slow-mo
#   just watch 4      # 4x slow-mo (prettier)
#   just watch 1      # normal speed
#   just watch 2 chrome
watch dilation='2' dev='macos':
    {{flutter}} test integration_test/development_smoke_test.dart -d {{dev}} \
        --dart-define-from-file={{dev_config}} \
        --dart-define=SMOKE_WATCH=true \
        --dart-define=SMOKE_DILATION={{dilation}}

# Production route-policy integration test (dev routes must be absent in prod).
test-prod-routes dev='macos':
    {{flutter}} test integration_test/production_routes_test.dart -d {{dev}} --dart-define-from-file={{prod_config}}

# Validate Android TV launcher metadata, native detection, themes, and assets.
android-tv-validate merged_manifest='':
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ -n '{{merged_manifest}}' ]]; then
        python3 tool/android_tv/validate_android_tv.py \
            --merged-manifest '{{merged_manifest}}'
    else
        python3 tool/android_tv/validate_android_tv.py
    fi

# Build the shared production APK and validate its Android TV packaging.
android-tv-build:
    #!/usr/bin/env bash
    set -euo pipefail

    # A flutter-tvos invocation writes checkout-local plugin metadata. Always
    # restore it with the stock SDK before entering the Android release lane.
    {{flutter}} pub get
    {{flutter}} build apk --release --dart-define-from-file={{prod_config}}
    merged_manifest="$(
        find build/app/intermediates/merged_manifest/release \
            -name AndroidManifest.xml -print -quit
    )"
    if [[ -z "$merged_manifest" ]]; then
        echo 'Release merged manifest was not found.' >&2
        exit 1
    fi
    python3 tool/android_tv/validate_android_tv.py \
        --merged-manifest "$merged_manifest"
    apk=build/app/outputs/flutter-apk/app-release.apk
    apk_entries="$(mktemp)"
    trap 'rm -f "$apk_entries"' EXIT
    unzip -Z1 "$apk" >"$apk_entries"
    grep -qx 'lib/armeabi-v7a/libflutter\.so' "$apk_entries"
    grep -qx 'lib/arm64-v8a/libflutter\.so' "$apk_entries"
    build_tools="$(
        find "$ANDROID_HOME/build-tools" -mindepth 1 -maxdepth 1 \
            -type d -print | sort -V | tail -n 1
    )"
    "$build_tools/zipalign" -c -P 16 -v 4 "$apk"
    {{flutter}} build appbundle --release \
        --dart-define-from-file={{prod_config}}

# --- release builds (production config) ---------------------------------------
# Production release build: just build <target>
# targets: apk | appbundle | ios | macos | linux | windows | web
build target:
    #!/usr/bin/env bash
    set -euo pipefail
    # Xcode 27's lipo rejects the multi-arch check Flutter 3.44 runs for a
    # universal macOS build, so build the host architecture there. CI's Xcode 26
    # still produces the universal app. Drop this after the next Flutter upgrade.
    if [[ '{{target}}' == 'macos' ]] && command -v xcodebuild >/dev/null 2>&1; then
        xcode_major="$(xcodebuild -version | sed -nE '1s/Xcode ([0-9]+).*/\1/p')"
        if [[ "${xcode_major:-0}" -ge 27 ]]; then
            echo "Xcode $xcode_major: building macOS for $(uname -m) only." >&2
            export FLUTTER_XCODE_ARCHS="$(uname -m)"
        fi
    fi
    {{flutter}} build {{target}} --release --dart-define-from-file={{prod_config}}

# iOS release without code signing (matches the release workflow).
build-ios:
    {{flutter}} build ios --release --no-codesign --dart-define-from-file={{prod_config}}

# --- in-repo dummy backend (C3) ----------------------------------------------
# TypeScript contract tests for the dummy backend.
server-test:
    cd tools/hono_server && bun install --frozen-lockfile && bun test

# Start the standalone Hono (TypeScript) dummy backend on a configurable port
# (default 8080). Implements the app's /v1/* API contract; never compiled into
# the app. Uses Bun when available, otherwise Node via tsx.
backend port='8080':
    #!/usr/bin/env bash
    set -euo pipefail

    cd tools/hono_server
    if [[ ! -d node_modules ]]; then
        if command -v bun >/dev/null 2>&1; then
            bun install
        elif command -v npm >/dev/null 2>&1; then
            npm install
        else
            echo 'Install Bun (preferred) or Node/npm to run the backend.' >&2
            exit 1
        fi
    fi

    if command -v bun >/dev/null 2>&1; then
        exec bun run src/index.ts --port '{{port}}'
    elif command -v npx >/dev/null 2>&1; then
        exec npx tsx src/index.ts --port '{{port}}'
    else
        echo 'Install Bun (preferred) or Node to run the backend.' >&2
        exit 1
    fi
