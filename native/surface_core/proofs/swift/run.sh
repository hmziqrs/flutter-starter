#!/usr/bin/env bash
# Runs the Swift proof on macOS and, with a simulator UDID, inside that simulator. Boot the
# simulator first with `xcrun simctl boot`. Simulator.app is not needed.
# Usage: run.sh <host port> [simulator udid]
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
port="$1"
udid="${2:-}"
base="http://127.0.0.1:$port"
https_url=https://example.com
bad_cert=https://expired.badssl.com/
token="$(bash "$here/../make_session.sh" "$base")"

# Each mode is a fresh process, so peak memory belongs to that mode alone.
run_modes() {
  local label="$1"
  shift
  echo "=== $label ==="
  "$@" baseline
  "$@" fetch "$base"
  "$@" fetch "$base" "$token"
  "$@" https "$https_url"
  "$@" full "$base" "$token" "$https_url" "$bad_cert"
  "$@" soak "$base" 400
}

run_modes macos "$here/build/macos/surface_proof"
if [[ -n "$udid" ]]; then
  run_modes "ios-simulator $udid" xcrun simctl spawn "$udid" "$here/build/ios-sim/surface_proof"
fi
