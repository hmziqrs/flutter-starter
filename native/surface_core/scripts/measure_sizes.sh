#!/usr/bin/env bash
# Reports library sizes, ELF details and linked-binary deltas. Run after scripts/build_all.sh
# and proofs/swift/build.sh.
set -euo pipefail

crate="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$crate"
ndk="${ANDROID_NDK_HOME:-$HOME/Library/Android/sdk/ndk/29.0.14206865}"
llvm="$ndk/toolchains/llvm/prebuilt/darwin-x86_64/bin"

bytes() { stat -f %z "$1"; }
gzipped() { gzip -9c "$1" | wc -c | tr -d ' '; }

echo "== Android .so (stripped by the release profile) =="
for abi in arm64-v8a armeabi-v7a x86_64; do
  so="dist/android/jniLibs/$abi/libsurface_core.so"
  echo "$abi bytes=$(bytes "$so") gzip9=$(gzipped "$so")"
  echo "  LOAD align: $("$llvm/llvm-readelf" -lW "$so" | awk '/LOAD/{print $NF}' | sort -u | tr '\n' ' ')"
  echo "  NEEDED: $("$llvm/llvm-readelf" -dW "$so" | awk '/NEEDED/{print $NF}' | tr '\n' ' ')"
  echo "  symtab or debug sections: $("$llvm/llvm-readelf" -SW "$so" | grep -cE '\.symtab|\.debug' || true)"
  echo "  exports: $("$llvm/llvm-nm" -D --defined-only "$so" | awk '{print $NF}' | sort | tr '\n' ' ')"
done

echo
echo "== Apple .a =="
for target in aarch64-apple-darwin aarch64-apple-ios aarch64-apple-ios-sim; do
  a="dist/apple/$target/libsurface_core.a"
  raw="target/$target/release/libsurface_core.a"
  echo "$target unstripped=$(bytes "$raw") stripped=$(bytes "$a") stripped_gzip9=$(gzipped "$a")"
done
echo "xcframework: $(du -sk dist/apple/SurfaceCore.xcframework | awk '{print $1}') KiB"
echo "exports (ios): $(nm -gU dist/apple/aarch64-apple-ios/libsurface_core.a 2>/dev/null | grep -E ' T _surface_core' | awk '{print $NF}' | sort -u | tr '\n' ' ')"

echo
echo "== Size added to a stripped, dead-stripped, linked binary =="
sizes="proofs/swift/build/size"
for platform in macos ios; do
  empty="$(bytes "$sizes/$platform-empty")"
  pure="$(bytes "$sizes/$platform-pure")"
  full="$(bytes "$sizes/$platform-full")"
  echo "$platform empty=$empty pure_only=$pure (+$((pure - empty))) all_functions=$full (+$((full - empty)))"
  size -m "$sizes/$platform-full" | grep -E '^Segment (__TEXT|__DATA|__DATA_CONST)' | sed 's/^/  full /'
done

echo
echo "== Symbols the iOS binary imports from the system =="
nm -u "$sizes/ios-empty" | sort -u >"$sizes/ios-empty.undefined"
nm -u "$sizes/ios-full" | sort -u >"$sizes/ios-full.undefined"
echo "Added by the library:"
comm -13 "$sizes/ios-empty.undefined" "$sizes/ios-full.undefined" | tr '\n' ' '
echo
echo
echo "Linked libraries (ios full):"
otool -L "$sizes/ios-full" | tail -n +2

echo
echo "Android APK:"
ls -l proofs/android/build/surface_core_proof.apk 2>/dev/null || echo "not built"
