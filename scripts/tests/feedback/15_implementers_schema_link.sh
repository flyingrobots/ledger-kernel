#!/usr/bin/env bash
set -euo pipefail
f=docs/implementation/implementers.md
rg -n "https://github.com/.*/ledger-kernel/.*/schemas/compliance_report.schema.json" "$f" >/dev/null
