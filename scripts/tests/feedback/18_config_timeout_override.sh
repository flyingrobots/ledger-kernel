#!/usr/bin/env bash
set -euo pipefail
f=scripts/harness/config.sample.toml
rg -n "^\[checks.C-4\]" "$f" >/dev/null
rg -n "^timeout_sec\s*=\s*\d+" "$f" >/dev/null
