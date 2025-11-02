This is a language‑agnostic Bats harness template you can copy into your implementation repo.

How to use
- Copy this directory into your repo (e.g., `tests/compliance-bats/`).
- Define `LEDGER_CLI` environment variable to point to your CLI binary, or implement the `lk()` function in `helpers.bash`.
- Remove `skip` lines from the C‑*.bats files as you wire each check.
- The authoritative artifact remains the compliance.json emitted by your CLI; these tests are optional developer ergonomics.

