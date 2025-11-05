#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/README.md
# Ensure at least one bash fence and one c or text fence exist
rg -n '^```bash$' "$f" >/dev/null
rg -n '^```(c|text)$' "$f" >/dev/null
