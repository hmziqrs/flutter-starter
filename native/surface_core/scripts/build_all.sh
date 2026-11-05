#!/usr/bin/env bash
# Builds every target into dist/. Needs rustup targets, cargo-ndk and an Android NDK.
#
#   dist/apple/<target>/libsurface_core.a
#   dist/apple/SurfaceCore.xcframework
#   dist/android/jniLibs/<abi>/libsurface_core.so
set -euo pipefail

crate_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$crate_dir"

# Keeps absolute paths from this checkout out of the binaries.
export RUSTFLAGS="--remap-path-prefix=$crate_dir=surface_core --remap-path-prefix=$HOME=~"

# Matches the app: iOS 15.0, macOS 12.0, Android minSdk 26.
export IPHONEOS_DEPLOYMENT_TARGET=15.0
export MACOSX_DEPLOYMENT_TARGET=12.0
android_api=26

ndk_root="${ANDROID_NDK_ROOT:-$HOME/Library/Android/sdk/ndk}"
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
  # shellcheck disable=SC2012 # NDK folder names are plain version numbers.
  ANDROID_NDK_HOME="$ndk_root/$(ls "$ndk_root" | sort -V | tail -1)"
  export ANDROID_NDK_HOME
fi

rm -rf dist
apple_targets=(aarch64-apple-darwin aarch64-apple-ios aarch64-apple-ios-sim)
for target in "${apple_targets[@]}"; do
  cargo build --release --locked --target "$target"
  mkdir -p "dist/apple/$target"
  cp "target/$target/release/libsurface_core.a" "dist/apple/$target/"
  # Removes local symbols and debug info. Exported symbols stay, so the linker still works.
  strip -S -x "dist/apple/$target/libsurface_core.a" 2>/dev/null
done

headers="$(mktemp -d)"
cp include/surface_core.h include/module.modulemap "$headers/"
xcodebuild -create-xcframework \
  -library dist/apple/aarch64-apple-darwin/libsurface_core.a -headers "$headers" \
  -library dist/apple/aarch64-apple-ios/libsurface_core.a -headers "$headers" \
  -library dist/apple/aarch64-apple-ios-sim/libsurface_core.a -headers "$headers" \
  -output dist/apple/SurfaceCore.xcframework
rm -rf "$headers"

cargo ndk --platform "$android_api" \
  -t arm64-v8a -t armeabi-v7a -t x86_64 \
  -o dist/android/jniLibs \
  build --release --locked

echo "NDK: $ANDROID_NDK_HOME"
find dist -type f \( -name '*.a' -o -name '*.so' \) -not -path '*.xcframework*' -exec ls -l {} +
