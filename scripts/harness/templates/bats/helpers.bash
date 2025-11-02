# shellcheck shell=bash

# Optional adapter for your CLI. Either:
#  - export LEDGER_CLI=/path/to/your-cli
#  - or implement lk() to call your CLI (handle args, working dir, etc.)

lk() {
  if [[ -n "${LEDGER_CLI:-}" ]]; then
    "$LEDGER_CLI" "$@"
  else
    echo "ERROR: Set LEDGER_CLI to your CLI path or edit helpers.bash to implement lk()" >&2
    return 127
  fi
}

