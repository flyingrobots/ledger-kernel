#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/vectors-matrix.yml
# Expect an explicit compile command referencing the source and -o c_b3sum
rg -n -- "gcc .* -o c_b3sum .*scripts/vectors/c/blake3_id.c" "$f" >/dev/null
