#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "\t" "$f"; then
  echo "Found tabs in $f" >&2
  exit 1
fi
