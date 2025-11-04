#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
rg -n "for dir in schemas tests/vectors scripts/vectors; do" "$f" >/dev/null
rg -n "ERROR: Required directory '" "$f" >/dev/null
