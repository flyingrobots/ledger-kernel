# Minimal Polyglot Compliance Orchestrator

This orchestrator runs implementation‑specific checks (C‑1..C‑5), aggregates results, and emits a standards‑conformant `compliance.json` report.

Features
- Configured via TOML (checks, clauses, command lines, levels, timeouts)
- Timeout + simple sandboxing (`ulimit -c 0`)
- Validates the final report against `schemas/compliance_report.schema.json` (best‑effort: Python jsonschema if available, otherwise jq structural checks)

Usage

```bash
scripts/harness/run.sh \
  --config scripts/harness/config.sample.toml \
  --output compliance.json \
  --schema schemas/compliance_report.schema.json \
  --level core   # or: policy | wasm | all
```

Config (TOML)

```toml
[orchestrator]
implementation = "example-impl"
version = "0.1.0"
timeout_sec = 30

[checks.C-1]
clause = ["FS-10"]
level = "core"
cmd = "your-cli canonicalize --input tests/vectors/core/entry.json --print-id"

[checks.C-2]
clause = ["FS-7","FS-8"]
level = "core"
cmd = "your-cli append --non-ff; test $? -ne 0"
```

Exit codes → status mapping
- 0 → PASS
- 64 → PARTIAL
- 124 → FAIL (timeout)
- anything else → FAIL

Notes
- The orchestrator is language‑agnostic: each check is just a shell command.
- Add more checks or levels by extending the TOML `checks.*` sections.
- For robust schema validation, install Python `jsonschema` or use `ajv` and adapt the script.
