#!/usr/bin/env bats
# Template test for C-1 (FS-10 canonical JSON -> BLAKE3-256)

load './helpers.bash'

@test 'C-1 canonical JSON -> id' {
  skip "template: set LEDGER_CLI and remove skip"
  # Example: your CLI could canonicalize and print id; adapt as needed
  run lk canonicalize --input tests/vectors/core/entry_canonical.json --print-id
  [ "$status" -eq 0 ]
  expected=$(cat tests/vectors/core/entry_expected_id.txt)
  [ "$output" = "$expected" ]
}

