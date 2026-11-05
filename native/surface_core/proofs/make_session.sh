#!/usr/bin/env bash
# Prints an access token for a new account on the local dummy backend. The display name holds
# the emoji the harnesses expect back, which proves UTF-8 survives each boundary.
# Usage: make_session.sh http://127.0.0.1:18473
set -euo pipefail

base="$1"
email="proof-$(date +%s)-$RANDOM@example.test"

registered="$(curl -fsS "$base/v1/auth/register" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$email\",\"password\":\"dummy-backend-test-value\",\"displayName\":\"Proof 🚀\"}")"

verify_body="$(printf '%s' "$registered" | python3 -I -c '
import json, sys
r = json.load(sys.stdin)
print(json.dumps({"attempt_token": r["attempt_token"], "code": r["dev_code"]}))')"

curl -fsS "$base/v1/otp/verify" -H 'Content-Type: application/json' -d "$verify_body" |
  python3 -I -c 'import json, sys; print(json.load(sys.stdin)["access_token"])'
