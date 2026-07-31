# Flutter starter — common dev tasks. Run `just` (no args) to list recipes.
#
# Integration tests have two modes:
#   just smoke   → headless "coverage" mode (CI behavior: pins phone/tablet/desktop
#                  sizes; the macOS window shows "Test starting...", which is expected)
#   just watch   → visible mode: real window, slowed animations, step pauses

dev_config  := "config/development.json"
prod_config := "config/production.json"
flutter     := "flutter"

# List available recipes.
default:
    @just --list --unsorted

# --- setup --------------------------------------------------------------------
# Resolve dependencies.
deps:
    {{flutter}} pub get

# Regenerate slang translations and other build_runner outputs.
gen:
    dart run build_runner clean
    rm -f lib/i18n/translations.g.dart lib/i18n/translations_en.g.dart lib/i18n/translations_ar.g.dart lib/i18n/translations_zh_Hans.g.dart
    dart run build_runner build

# Remove all build artifacts.
clean:
    {{flutter}} clean

# --- quality ------------------------------------------------------------------
# Static analysis (CI uses --fatal-infos).
analyze:
    {{flutter}} analyze --fatal-infos

# Format the codebase in place.
format:
    dart format lib test integration_test

# Fail if anything is unformatted (CI gate).
format-check:
    dart format --output=none --set-exit-if-changed lib test integration_test

# Verify generated code is committed and in sync (CI gate).
gen-check:
    dart run build_runner clean
    rm -f lib/i18n/translations.g.dart lib/i18n/translations_en.g.dart lib/i18n/translations_ar.g.dart lib/i18n/translations_zh_Hans.g.dart
    dart run build_runner build
    git diff --exit-code

# --- native splash (codegen; config in flutter_native_splash.yaml) ------------
# Regenerate the committed native launch assets (iOS storyboard, Android
# drawable + Android-12 styles, web splash). Mirrors `gen`/`gen-check`: review
# the committed native diff before accepting the CLI output.
splash:
    dart run flutter_native_splash:create

# Remove the generated native splash launch assets (undo `splash`).
splash-remove:
    dart run flutter_native_splash:remove

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
# zero-backend development.json (the same merge CI's smoke flow uses), so no
# separate config file is needed. host defaults to loopback; pass 10.0.2.2 for
# the Android emulator (its alias for host loopback).
run-backend dev='macos' host='127.0.0.1':
    {{flutter}} run -d {{dev}} --target=lib/main_dev.dart \
        --dart-define-from-file={{dev_config}} \
        --dart-define=BACKEND_BASE_URL=http://{{host}}:8080

# --- tests --------------------------------------------------------------------
# All non-golden unit + widget tests (the CI quality job).
test:
    {{flutter}} test $(find test -type f -name '*_test.dart' ! -path 'test/goldens/*')

# Canonical golden baseline (run on macOS, as in CI).
test-goldens:
    {{flutter}} test test/goldens/canonical_matrix_golden_test.dart

# Dev smoke integration test — HEADLESS coverage mode (CI behavior).
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
    {{flutter}} build {{target}} --release --dart-define-from-file={{prod_config}}

# iOS release without code signing (matches CI).
build-ios:
    {{flutter}} build ios --release --no-codesign --dart-define-from-file={{prod_config}}

# --- in-repo dummy backend (C3) ----------------------------------------------
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
