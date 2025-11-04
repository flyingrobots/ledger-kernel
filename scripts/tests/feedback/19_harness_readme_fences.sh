#!/usr/bin/env bash
set -euo pipefail
f=scripts/harness/README.md
# Check opening fences only (```lang)
ok=1
while IFS= read -r line; do
  if echo "$line" | grep -qE '^```[a-zA-Z]+'; then
    ok=0; break
  fi
done < "$f"
if [ $ok -ne 0 ]; then
  echo "No opening fenced code block with language found in $f" >&2
  exit 1
fi
