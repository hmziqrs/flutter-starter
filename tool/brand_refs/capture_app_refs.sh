#!/usr/bin/env bash
# Rebuild build/brand-refs/app/: headless photographs of the brand kit's App
# blocks (auth layout, shell, settings, states, pricing) at desktop and phone
# width, to compare the real screens against. Uses a headless Chrome, so nothing
# appears on the desktop.
#
#   tool/brand_refs/capture_app_refs.sh [path to the brand repo, default ~/brand]
set -euo pipefail

brand="${1:-$HOME/brand}"
storybook="$brand/packages/brand-svelte/storybook-static"
out="$(cd "$(dirname "$0")/../.." && pwd)/build/brand-refs/app"
chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
port=6107

if [[ ! -f "$storybook/index.json" ]]; then
  echo "No built storybook at $storybook. Build it in the brand repo first." >&2
  exit 1
fi

mkdir -p "$out"
profile="$(mktemp -d)"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$storybook" >/dev/null 2>&1 &
server=$!
trap 'kill "$server" 2>/dev/null || true; rm -rf "$profile"' EXIT
sleep 1

shot() {
  "$chrome" --headless=new --disable-gpu --hide-scrollbars --force-dark-mode \
    --user-data-dir="$profile" --virtual-time-budget=6000 --window-size="$2" \
    --screenshot="$out/$3" "http://127.0.0.1:$port/iframe.html?id=$1&viewMode=story" \
    >/dev/null 2>&1
}

for id in app-auth-layout--split app-auth-layout--centered app-shell--sidebar \
  app-shell--collapsed app-shell--page app-settings--form-clean app-settings--section \
  app-auth--sign-in-form app-auth--verify-email app-states--error-not-found \
  app-states--empty-first-use site-pricing-pricing-plans--default; do
  shot "$id" 1440,900 "$id.desktop.png"
done
for id in app-auth-layout--split-mobile app-auth--sign-in-form-mobile \
  app-auth--verify-email-mobile app-settings--section-mobile app-shell--header-on-mobile; do
  shot "$id" 390,844 "$id.phone.png"
done
echo "Wrote $out"
