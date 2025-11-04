#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/src/lib.rs
# Check for a panic handler attribute
if ! rg -n "^#\[panic_handler\]" "$f" >/dev/null; then
  echo "panic handler missing in $f" >&2
  exit 1
fi
# Try to build (requires toolchain + target installed)
cargo build --release --target wasm32-unknown-unknown >/dev/null
