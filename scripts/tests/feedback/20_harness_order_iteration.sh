#!/usr/bin/env bash
set -euo pipefail
f=scripts/harness/run.sh
# Must not iterate associative array keys directly
if rg -n -- 'for key in "\$\{!check_cmd\[@\]\}"' "$f"; then
  echo "Unordered associative array iteration detected" >&2
  exit 1
fi
# Must iterate using check_order array
rg -n -- 'check_order\[@\]' "$f" >/dev/null
rg -n -- 'for key in "\$\{check_order\[@\]\}"' "$f" >/dev/null
