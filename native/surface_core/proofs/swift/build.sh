#!/usr/bin/env bash
# Builds the Swift proofs into build/. Run scripts/build_all.sh first.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
crate="$(cd "$here/../.." && pwd)"
out="$here/build"
rm -rf "$out"

# link <name> <swift target> <sdk> <rust target> <sources...>
# Rust's native-static-libs for these targets are only libSystem and libc, which swiftc
# already links, so nothing else is passed. The link fails loudly if that ever changes.
link() {
  local name="$1" swift_target="$2" sdk="$3" rust_target="$4"
  shift 4
  mkdir -p "$out/$(dirname "$name")"
  local lib="$crate/dist/apple/$rust_target/libsurface_core.a"
  local module_cache="$out/module-cache"
  xcrun --sdk "$sdk" swiftc -O -whole-module-optimization \
    -target "$swift_target" \
    -module-cache-path "$module_cache" \
    -I "$crate/include" \
    -Xlinker -dead_strip \
    "$@" "$lib" \
    -o "$out/$name"
}

# strip_and_sign <path>: what a release build ships.
strip_and_sign() {
  strip -x "$1"
  codesign --force --sign - "$1" 2>/dev/null
}

proof_sources=("$here/main.swift" "$crate/bindings/swift/SurfaceCore.swift")

link macos/surface_proof arm64-apple-macos12.0 macosx aarch64-apple-darwin "${proof_sources[@]}"
link ios-sim/surface_proof arm64-apple-ios15.0-simulator iphonesimulator aarch64-apple-ios-sim \
  "${proof_sources[@]}"
# Link check only. There is no device here to run it on.
link ios-device/surface_proof arm64-apple-ios15.0 iphoneos aarch64-apple-ios "${proof_sources[@]}"
codesign --force --sign - "$out/ios-sim/surface_proof" 2>/dev/null

# Size variants. The empty one still gets the archive on its link line, and dead stripping
# drops all of it, so the delta is only what the calls pull in.
for platform in macos ios; do
  if [[ "$platform" == macos ]]; then
    target=arm64-apple-macos12.0 sdk=macosx rust=aarch64-apple-darwin
  else
    target=arm64-apple-ios15.0 sdk=iphoneos rust=aarch64-apple-ios
  fi
  for variant in EMPTY PURE FULL; do
    name="size/$platform-$(printf '%s' "$variant" | tr '[:upper:]' '[:lower:]')"
    flags=()
    [[ "$variant" != EMPTY ]] && flags=(-D "$variant")
    link "$name" "$target" "$sdk" "$rust" ${flags[@]+"${flags[@]}"} "$here/size_probe.swift"
    strip_and_sign "$out/$name"
  done
done

echo "Built in $out"
