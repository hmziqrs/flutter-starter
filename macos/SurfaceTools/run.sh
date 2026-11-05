#!/bin/sh
# Builds and runs the headless surface tool: the widget and menu code compiled on its own, with no
# app, no Flutter engine, nothing on screen and no input events.
#
#   macos/SurfaceTools/run.sh check
#   macos/SurfaceTools/run.sh render <output dir>
set -eu

macos="$(cd "$(dirname "$0")/.." && pwd)"
fonts="$macos/../assets/fonts/Onest"
build="${TMPDIR:-/tmp}/surface-tool"
mkdir -p "$build"

swiftc -swift-version 5 -O \
  -target "$(uname -m)-apple-macos14.0" \
  -module-name SurfaceTool \
  -o "$build/surface-tool" \
  "$macos/SurfaceShared/SurfaceSnapshot.swift" \
  "$macos/SurfaceShared/SurfaceLook.swift" \
  "$macos/SurfaceWidgets/SurfaceWidgetContent.swift" \
  "$macos/Runner/SurfaceRoutes.swift" \
  "$macos/Runner/SurfaceMenu.swift" \
  "$macos/SurfaceTools/main.swift"

command="${1:-}"
case "$command" in
  render) exec "$build/surface-tool" render "${2:?output directory}" "$fonts" ;;
  check) exec "$build/surface-tool" check "$fonts" ;;
  *) exec "$build/surface-tool" "$@" ;;
esac
