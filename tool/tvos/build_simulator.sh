#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
environment="${1:-development}"
config="$repo_root/config/$environment.json"

if [[ ! -f "$config" ]]; then
  printf 'Unknown configuration: %s\n' "$config" >&2
  exit 1
fi

cd "$repo_root"
exec "$repo_root/tool/tvos/flutter-tvos.sh" build tvos \
  --simulator --debug --dart-define-from-file="$config"
