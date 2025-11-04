#!/usr/bin/env bash
set -euo pipefail
f=docs/spec/wire-format.md
line=$(rg -n "^### CBOR Canonical Profile \(Optional\)" "$f" | cut -d: -f1 | head -n1)
[ -n "$line" ]
prev=$((line-1))
# Extract previous line
pl=$(sed -n "${prev}p" "$f")
[ -z "$pl" ] || { echo "No blank line before CBOR heading" >&2; exit 1; }
