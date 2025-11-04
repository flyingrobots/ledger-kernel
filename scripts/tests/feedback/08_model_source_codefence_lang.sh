#!/usr/bin/env bash
set -euo pipefail
f=docs/spec/model-source.md
# Fail if any bare code fence exists (exact line of ```)
if grep -xF '```' "$f"; then
  echo "Found bare code fence without language in $f" >&2
  exit 1
fi
