#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/src/lib.rs
rg -n '^/// Safety' "$f" >/dev/null
