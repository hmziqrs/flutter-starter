#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=versions.env
source "$repo_root/tool/tvos/versions.env"

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}"
toolchain_dir="${1:-${FLUTTER_TVOS_HOME:-$cache_root/flutter-tvos/$FLUTTER_TVOS_TAG}}"

assert_equal() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_sha256() {
  local expected="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    printf 'Missing engine artifact: %s\n' "$path" >&2
    exit 1
  fi
  assert_equal "$expected" "$(shasum -a 256 "$path" | awk '{print $1}')" "$path SHA-256"
}

assert_equal "$FLUTTER_TVOS_COMMIT" \
  "$(git -C "$toolchain_dir" rev-parse HEAD)" "flutter-tvos commit"
assert_equal "$FLUTTER_TVOS_TAG" \
  "$(git -C "$toolchain_dir" describe --tags --exact-match HEAD)" "flutter-tvos tag"
assert_equal "$FLUTTER_TVOS_FRAMEWORK_COMMIT" \
  "$(git -C "$toolchain_dir/flutter" rev-parse HEAD)" "Flutter framework commit"
assert_equal "$FLUTTER_TVOS_FRAMEWORK_COMMIT" \
  "$(tr -d '[:space:]' < "$toolchain_dir/bin/internal/flutter.version")" \
  "pinned Flutter framework commit"
assert_equal "$FLUTTER_TVOS_ENGINE_VERSION" \
  "$(tr -d '[:space:]' < "$toolchain_dir/bin/internal/engine.version")" \
  "tvOS engine version"
assert_equal "$FLUTTER_TVOS_ENGINE_VERSION" \
  "$(tr -d '[:space:]' < "$toolchain_dir/flutter/bin/cache/tvos-sdk.stamp")" \
  "cached tvOS engine version"

artifact_root="$toolchain_dir/engine_artifacts"
assert_sha256 "$FLUTTER_TVOS_DEBUG_SIM_SHA256" \
  "$artifact_root/tvos_debug_sim_arm64/Flutter.xcframework/tvos-arm64-simulator/Flutter.framework/Flutter"
assert_sha256 "$FLUTTER_TVOS_DEBUG_DEVICE_SHA256" \
  "$artifact_root/tvos_debug_arm64/Flutter.xcframework/tvos-arm64/Flutter.framework/Flutter"
assert_sha256 "$FLUTTER_TVOS_PROFILE_DEVICE_SHA256" \
  "$artifact_root/tvos_profile_arm64/Flutter.xcframework/tvos-arm64/Flutter.framework/Flutter"
assert_sha256 "$FLUTTER_TVOS_RELEASE_DEVICE_SHA256" \
  "$artifact_root/tvos_release_arm64/Flutter.xcframework/tvos-arm64/Flutter.framework/Flutter"

printf 'flutter-tvos pin, framework, engine version, and engine checksums verified.\n'
