---
title: Compliance
---

# Compliance

This section defines how an implementation demonstrates conformance to the Ledger‑Kernel specification. Tests are keyed to the numbered clauses in the Model (M‑x) and Formal Spec (FS‑x), and use canonical encodings from Wire Format.

## 1. Purpose and Scope

To demonstrate conformance of an implementation to FS‑1 … FS‑14 and M‑1 … M‑9 using a reproducible harness that runs offline against repository data.

Outputs include a machine‑readable report (see §4) and level verdicts (Core / Policy / WASM).

## 2. Levels

### 2.1 Core
Clauses: FS‑1, FS‑4 … FS‑8, FS‑10 … FS‑12; M‑4 … M‑8

Validates canonicalization and hashing, append‑only total order, and fast‑forward ref semantics.

### 2.2 Policy
Clauses: FS‑3, FS‑6, FS‑9; M‑7, M‑9

Validates deterministic policy evaluation and offline verification.

### 2.3 WASM
Clauses: FS‑9 (extended)

Validates policy sandbox determinism: no clock, randomness, network, or filesystem access; fixed inputs yield identical outputs.

## 3. Harness Checks

| ID | Clause(s) | Test | Expected Result |
|---|---|---|---|
| C‑1 | FS‑10 | Canonicalize a known JSON and compute id | Hash = expected BLAKE3‑256 (and optional SHA‑256 mirror) |
| C‑2 | FS‑7, FS‑8 | Attempt rebase / non‑fast‑forward update on the ledger ref | Operation rejected; ref unchanged |
| C‑3 | FS‑11 | Append an entry with a timestamp earlier than parent | Validation error; append rejected |
| C‑4 | FS‑3, FS‑9 | Run the same policy on the same inputs across N runs | Identical accept/deny results and diagnostics |
| C‑5 | FS‑6 | Verify a ledger offline (no network) | PASS; all entries/attestations/policies verify |

Notes
- Implementations MAY include additional checks; the above are the minimal required set for each level.
- Where applicable, each check SHOULD cite the exact FS‑x / M‑x it substantiates in the report.

## 4. Report Format

The harness emits a JSON file conforming to `schemas/compliance_report.schema.json`.

Example
```json
{
  "implementation": "libgitledger",
  "version": "0.1.0",
  "date": "2025-11-03T00:00Z",
  "results": [
    { "id": "C-1", "clause": ["FS-10"], "status": "PASS" },
    { "id": "C-2", "clause": ["FS-7","FS-8"], "status": "PASS" }
  ],
  "summary": {
    "core": "PASS",
    "policy": "PASS",
    "wasm": "N/A"
  }
}
```

Status values
- `PASS` — satisfies the clause(s)
- `PARTIAL` — optional diagnostics differ or informative fields missing
- `FAIL` — violates a MUST/SHALL requirement
- `N/A` — not applicable for this level or configuration

## 5. Execution

Reference fixtures (paths are informative; implementations MAY organize differently):
- Core vectors: `tests/vectors/core/*.json`
- Determinism replay sets: `tests/replay/*.ledger`
- WASM sandbox policies: `tests/policy/wasm/*.wasm` with fixed inputs

Harness
- Run in offline mode; network access MUST NOT be required (FS‑6).
- Emit `compliance.json` and (optionally) JUnit for CI.

## 6. Scoring / Conformance

- A level verdict is `PASS` only if all required checks for that level are `PASS`.
- `PARTIAL` indicates informative differences only; review required before promoting to `PASS`.
- Any `FAIL` in a required check yields a `FAIL` verdict for that level.

## 7. Submission

Implementations submit:
- `compliance.json` (see §4)
- A manifest of fixture hashes used (e.g., BLAKE3‑256 of input vectors)
- CI artifact links (optional)

Badges
- CI may publish a badge based on the aggregated verdicts (`summary` block).

## 8. Cross‑References

- [Model](/spec/model) — M‑1 … M‑9
- [Formal Spec](/spec/formal-spec) — FS‑1 … FS‑14
- [Wire Format](/spec/wire-format) — Canonical encodings

