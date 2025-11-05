#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
# Get last non-empty char
if [ ! -f "$f" ]; then echo "release.yml missing" >&2; exit 1; fi
last=$(tail -c 1 "$f" | od -An -t u1)
# 10 = newline; we want last char to NOT be newline
if [ "$last" = " 10" ]; then
  echo "Trailing newline at EOF in $f" >&2
  exit 1
fi
