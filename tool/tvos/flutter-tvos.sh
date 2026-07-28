#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
# shellcheck source=versions.env
source "$repo_root/tool/tvos/versions.env"

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}"
toolchain_dir="${FLUTTER_TVOS_HOME:-$cache_root/flutter-tvos/$FLUTTER_TVOS_TAG}"

if [[ ! -x "$toolchain_dir/bin/flutter-tvos" ]]; then
  echo "Pinned flutter-tvos is missing. Run tool/tvos/bootstrap.sh." >&2
  exit 1
fi
if [[ "$(git -C "$toolchain_dir" rev-parse HEAD)" != "$FLUTTER_TVOS_COMMIT" ]]; then
  echo "Pinned flutter-tvos commit verification failed." >&2
  exit 1
fi

exec "$toolchain_dir/bin/flutter-tvos" "$@"
