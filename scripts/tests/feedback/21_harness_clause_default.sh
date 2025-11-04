#!/usr/bin/env bash
set -euo pipefail
f=scripts/harness/run.sh
if rg -n -- 'check_clause\[\$key\]:-"-"' "$f"; then
  echo "Bogus default '-' for clauses found" >&2
  exit 1
fi
# Must use empty default and append_result handles []
rg -n -- 'check_clause\[\$key\]:-\}' "$f" >/dev/null
rg -n -- 'if \[\[ -z "\$clauses_csv" \]\]; then' "$f" >/dev/null
