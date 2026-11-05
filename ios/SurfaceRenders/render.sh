#!/bin/sh
# Renders every native surface to PNG on a booted iOS simulator, without opening it.
#
#   ios/SurfaceRenders/render.sh <simulator udid> <output directory>
set -eu

UDID="$1"
OUTPUT="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
SURFACES="$HERE/../StarterSurfaces"
FONTS="$(cd "$HERE/../../assets/fonts/Onest" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

xcrun --sdk iphonesimulator swiftc \
  -target arm64-apple-ios17.0-simulator \
  -swift-version 5 \
  -parse-as-library \
  -o "$WORK/render" \
  "$HERE/main.swift" \
  "$SURFACES/SurfaceStyle.swift" \
  "$SURFACES/SurfaceGauge.swift" \
  "$SURFACES/HomeWidgetViews.swift" \
  "$SURFACES/LockWidgetViews.swift" \
  "$SURFACES/LiveActivityViews.swift" \
  "$SURFACES/Shared/SurfaceSnapshot.swift"

xcrun simctl spawn "$UDID" "$WORK/render" "$OUTPUT" "$FONTS"
