#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "^12\. Future Work$" "$f"; then
  echo "Found list-style '12. Future Work' — should be '## 12. Future Work'" >&2
  exit 1
fi
