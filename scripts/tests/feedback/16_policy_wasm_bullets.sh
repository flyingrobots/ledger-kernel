#!/usr/bin/env bash
set -euo pipefail
f=docs/spec/policy-wasm.md
# Count bullets that start with '- No '
count=$(rg -n "^- No " "$f" || true | wc -l | tr -d ' ')
if [ "$count" -ge 3 ]; then
  echo "Found repetitive '- No' bullets ($count)" >&2
  exit 1
fi
