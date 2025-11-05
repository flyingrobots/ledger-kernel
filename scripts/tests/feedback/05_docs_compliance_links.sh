#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "\./SPEC\.md|\./MODEL\.md" "$f"; then
  echo "Found broken relative links in $f" >&2
  exit 1
fi
