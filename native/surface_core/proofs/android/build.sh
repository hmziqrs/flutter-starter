#!/usr/bin/env bash
# Builds the proof APK with the SDK tools directly: no Gradle, and nothing touches android/.
# Run scripts/build_all.sh first.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
crate="$(cd "$here/../.." && pwd)"
out="$here/build"
sdk="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
tools="$sdk/build-tools/36.1.0"
android_jar="$sdk/platforms/android-36/android.jar"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

rm -rf "$out"
mkdir -p "$out/classes" "$out/dex" "$out/apk/lib"

javac --release 11 -nowarn -classpath "$android_jar" -d "$out/classes" \
  "$crate/bindings/android/com/example/surfacecore/SurfaceCore.java" \
  "$here/src/com/example/surfacecore/proof/ProofWidget.java"
"$tools/d8" --release --min-api 26 --lib "$android_jar" --output "$out/dex" \
  $(find "$out/classes" -name '*.class')
"$tools/aapt2" link -I "$android_jar" --manifest "$here/AndroidManifest.xml" \
  -o "$out/unsigned.apk"

cp -R "$crate/dist/android/jniLibs/"* "$out/apk/lib/"
cp "$out/dex/classes.dex" "$out/apk/"
# Stored, not deflated, so the loader can map the .so straight from the APK. This is what the
# Android Gradle plugin does by default, and it is what tests the 16 KB alignment for real.
(cd "$out/apk" && zip -q -0 -r ../unsigned.apk lib && zip -q ../unsigned.apk classes.dex)
"$tools/zipalign" -f -P 16 4 "$out/unsigned.apk" "$out/aligned.apk"

# A throwaway key used only for this proof.
keytool -genkeypair -keystore "$out/proof.keystore" -storepass proofonly -keypass proofonly \
  -alias proof -keyalg RSA -keysize 2048 -validity 2 -dname "CN=surface_core proof" 2>/dev/null
"$tools/apksigner" sign --ks "$out/proof.keystore" --ks-pass pass:proofonly \
  --out "$out/surface_core_proof.apk" "$out/aligned.apk"
"$tools/zipalign" -c -P 16 4 "$out/surface_core_proof.apk"

ls -l "$out/surface_core_proof.apk"
