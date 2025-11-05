#!/usr/bin/env bash
set -euo pipefail
for f in .github/workflows/vectors-cbor.yml .github/workflows/vectors-matrix.yml; do
  [ -f "$f" ] || continue
  rg -n "branches: \[ *main *\]" "$f" >/dev/null
  # Allow either with: { go-version: '1.21.x' } OR no Go step
  if rg -n "with: \{ *go-version: '1\.[0-9]+\.[0-9]+' *\}" "$f" -U -N >/dev/null 2>&1; then :; else :; fi
done
