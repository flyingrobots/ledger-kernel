---
title: Running the Compliance Harness
---

# Running the Compliance Harness

## 1. Purpose

The compliance harness validates an implementation against the Ledger‑Kernel specification and produces a standards‑conformant `compliance.json` report. Checks are keyed to Model (M‑1 … M‑9) and Formal Spec (FS‑1 … FS‑14) clauses, using canonical encodings from Wire Format.

## 2. Basic Workflow

```bash
git ledger verify --compliance
cat compliance.json | jq .
```

What happens
- The CLI runs the test groups in order: Core → Policy → WASM.
- Results are written to `compliance.json` in the current directory (schema in §4).

## 3. Sample Output

```json
{
  "implementation": "libgitledger",
  "version": "0.1.0",
  "results": [
    {"id": "C-1", "clause": ["FS-10"], "status": "PASS"},
    {"id": "C-2", "clause": ["FS-7","FS-8"], "status": "PASS"}
  ],
  "summary": {"core": "PASS", "policy": "PASS", "wasm": "N/A"}
}
```

Schema
- See [`schemas/compliance_report.schema.json`](https://github.com/flyingrobots/ledger-kernel/blob/main/schemas/compliance_report.schema.json)

## 4. Interpreting Results

| Status   | Meaning                                                      |
|----------|--------------------------------------------------------------|
| PASS     | Clause satisfied and reproducible.                           |
| PARTIAL  | Optional diagnostics differ; non‑critical variance.          |
| FAIL     | Violates a MUST / SHALL requirement.                         |
| N/A      | Clause not applicable for this implementation or level.      |

## 5. Clause Mapping (Core set)

| Check ID | Clauses → Spec Section          | Purpose                                |
|----------|----------------------------------|----------------------------------------|
| C‑1      | FS‑10 (Wire Format)             | Canonical JSON → BLAKE3‑256 hash match |
| C‑2      | FS‑7, FS‑8 (Formal Spec)        | Append‑only / fast‑forward ref behavior |
| C‑3      | FS‑11 (Formal Spec)             | Temporal monotonicity validation        |
| C‑4      | FS‑3, FS‑9 (Formal Spec)        | Deterministic policy evaluation         |
| C‑5      | FS‑6 (Formal Spec)              | Offline verify of ledger history        |

## 6. Advanced Use

```bash
# Limit scope to a level
git ledger verify --compliance --level core      # or: policy | wasm

# Choose a custom report location (default: ./compliance.json)
git ledger verify --compliance --output out/compliance.json

# Validate the report against the schema
git ledger verify --compliance --schema schemas/compliance_report.schema.json
```

## 7. Integration in CI

Example (GitHub Actions):

```yaml
steps:
  - run: git ledger verify --compliance --level core
  - run: jq -e '.summary.core == "PASS"' compliance.json
```

## 8. Cross‑References

- [Compliance Specification](/spec/compliance)
- [Formal Specification](/spec/formal-spec)
- [Wire Format](/spec/wire-format)

