#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/Cargo.toml
rg -n "^strip\s*=\s*true" "$f" >/dev/null
rg -n "^panic\s*=\s*\"abort\"" "$f" >/dev/null
