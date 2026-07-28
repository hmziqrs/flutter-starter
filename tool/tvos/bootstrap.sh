#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=versions.env
source "$repo_root/tool/tvos/versions.env"

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}"
toolchain_dir="${FLUTTER_TVOS_HOME:-$cache_root/flutter-tvos/$FLUTTER_TVOS_TAG}"

if [[ ! -d "$toolchain_dir/.git" ]]; then
  mkdir -p "$(dirname "$toolchain_dir")"
  git clone --branch "$FLUTTER_TVOS_TAG" --depth 1 \
    https://github.com/fluttertv/flutter-tvos.git "$toolchain_dir"
fi

actual_commit="$(git -C "$toolchain_dir" rev-parse HEAD)"
if [[ "$actual_commit" != "$FLUTTER_TVOS_COMMIT" ]]; then
  echo "flutter-tvos commit mismatch: expected $FLUTTER_TVOS_COMMIT, got $actual_commit" >&2
  exit 1
fi

"$toolchain_dir/bin/flutter-tvos" precache
"$repo_root/tool/tvos/verify_toolchain.sh" "$toolchain_dir"
printf 'Pinned flutter-tvos is ready at %s\n' "$toolchain_dir"
