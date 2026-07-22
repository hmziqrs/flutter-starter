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
    dart format .

# Fail if anything is unformatted (CI gate).
format-check:
    dart format --output=none --set-exit-if-changed .

# Verify generated code is committed and in sync (CI gate).
gen-check:
    dart run build_runner build
    git diff --exit-code

# --- run the app (development config) -----------------------------------------
# Run on a device (default macos): just run [chrome|macos|...]
run dev='macos':
    {{flutter}} run -d {{dev}} --dart-define-from-file={{dev_config}}

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

# --- release builds (production config) ---------------------------------------
# Production release build: just build <target>
# targets: apk | appbundle | ios | macos | linux | windows | web
build target:
    {{flutter}} build {{target}} --release --dart-define-from-file={{prod_config}}

# iOS release without code signing (matches CI).
build-ios:
    {{flutter}} build ios --release --no-codesign --dart-define-from-file={{prod_config}}
