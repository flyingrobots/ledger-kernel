#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/Makefile
if rg -n "\|\| true" "$f"; then
  echo "Makefile contains silent error suppression (|| true)" >&2
  exit 1
fi
# Ensure artifact check present
rg -n 'test -f \$\(OUT\)' "$f" >/dev/null
