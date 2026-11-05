#!/usr/bin/env bash
# Installs the proof, fires its AppWidgetProvider once per mode, prints the log and uninstalls.
# Broadcasts only: it starts no activity, so it never takes the screen on a shared emulator.
# Usage: run.sh <host port> [device serial]
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
port="$1"
serial="${2:-emulator-5554}"
package=com.example.surfacecore.proof
base="http://10.0.2.2:$port"
https_url=https://example.com
bad_cert=https://expired.badssl.com/
apk="$here/build/surface_core_proof.apk"

adb_device() { adb -s "$serial" "$@"; }

token="$(bash "$here/../make_session.sh" "http://127.0.0.1:$port")"

cleanup() { adb_device uninstall "$package" >/dev/null 2>&1 || true; }
trap cleanup EXIT

adb_device install -r "$apk" >/dev/null

# run_mode <mode> <wait seconds>: a fresh process each time, so memory is not shared between modes.
run_mode() {
  local mode="$1" budget="$2"
  adb_device shell am force-stop "$package"
  adb_device logcat -c
  adb_device shell am broadcast -a "$package.RUN" \
    -n "$package/.ProofWidget" -f 0x20 --eia appWidgetIds 1 \
    --es mode "$mode" --es base "$base" --es token "$token" \
    --es https "$https_url" --es badcert "$bad_cert" >/dev/null
  local waited=0
  until adb_device logcat -d -s SurfaceCoreProof:I | grep -q 'RESULT '; do
    sleep 1
    waited=$((waited + 1))
    if ((waited >= budget)); then
      echo "TIMED OUT in mode $mode"
      break
    fi
  done
  adb_device logcat -d -s SurfaceCoreProof:I AndroidRuntime:E DEBUG:F |
    sed -E 's/^.*(SurfaceCoreProof|AndroidRuntime|DEBUG) *: //'
}

for mode in baseline fetch https full soak; do
  echo "=== mode $mode ==="
  run_mode "$mode" 120
done

cleanup
trap - EXIT
if adb_device shell pm list packages | grep -q "$package"; then
  echo "UNINSTALL FAILED"
else
  echo "UNINSTALLED $package"
fi
