---
title: Implementers Guide
---

# Implementer's Guide

This page summarizes how to implement the **Ledger‑Kernel** spec and prove conformance with the compliance harness. It is language‑agnostic: any CLI that follows the contract below can integrate.

## 1. What you need to implement

### 1.1. Model & invariants

See [Model](/spec/model) (M‑1 … M‑9) and [Formal Spec](/spec/formal-spec) (FS‑1 … FS‑14).

### 1.2. Wire encodings

See [Wire Format](/spec/wire-format) (canonical JSON, hashing/signing, trailers) and the JSON Schemas under `schemas/`.

### 1.3. Compliance report

Your CLI should emit a `compliance.json` that validates against [`schemas/compliance_report.schema.json`](https://github.com/flyingrobots/ledger-kernel/blob/main/schemas/compliance_report.schema.json).

## 2. Recommended repo setup

### Option A — Submodule the spec (recommended)

1) In your implementation repo (e.g., Rust, C, Go):

```bash
git submodule add -b main https://github.com/flyingrobots/ledger-kernel external/ledger-kernel
git submodule update --init --recursive
```

2) In CI and locally, reference schemas and docs from `external/ledger-kernel/`.

### Option B — Vendor a release tarball

- Download a tagged release of this repo in CI; extract `schemas/` and (optionally) test vectors.

## 3. CLI contract (language‑agnostic)

Your CLI **SHOULD** expose a compliance mode that emits the standard report:

```bash
your-cli verify --compliance \
  [--level core|policy|wasm] \
  [--output compliance.json] \
  [--schema external/ledger-kernel/schemas/compliance_report.schema.json]
```

Status values **MUST** be exactly: `PASS` | `PARTIAL` | `FAIL` | `N/A`.

Minimum checks to implement (see [Compliance](/spec/compliance)):

- [ ] C‑1 → FS‑10: canonicalize known JSON → `id` = expected BLAKE3‑256
- [ ] C‑2 → FS‑7, FS‑8: reject non‑FF ref updates; ref unchanged
- [ ] C‑3 → FS‑11: reject timestamp earlier than parent
- [ ] C‑4 → FS‑3, FS‑9: deterministic policy evaluation → same result across runs
- [ ] C‑5 → FS‑6: offline verify of a small ledger → PASS

> [!NOTE]\
> If your runtime lacks a feature (e.g., WASM), mark the corresponding checks `N/A` and compute level verdicts accordingly.

## 4. Compliance report shape

The report **MUST** validate against the [schema](https://github.com/flyingrobots/ledger-kernel/blob/main/schemas/compliance_report.schema.json).

Example:

```json
{
  "implementation": "my-impl",
  "version": "0.1.0",
  "date": "2025-11-03T00:00Z",
  "results": [
    {"id": "C-1", "clause": ["FS-10"], "status": "PASS"}
  ],
  "summary": {"core": "PASS", "policy": "PASS", "wasm": "N/A"}
}
```

## 5. Running the harness

User‑facing instructions are in [CLI → Running the Harness](/cli/harness). Implementers can reuse that flow; point your users to it.

## 6. Optional: Polyglot harness template

This repo provides an optional Bats‑based skeleton you can copy into your project if you prefer shell‑level tests:

- `scripts/harness/templates/bats/helpers.bash` — define `lk()` or set `LEDGER_CLI` to adapt to your CLI name.
- `scripts/harness/templates/bats/C-1.bats` … — template tests (initially `skip`) you can un‑skip after wiring `lk()`.

These templates are illustrative and not required; the normative artifact is the `compliance.json` report.

## 7. CI examples

### Rust (cargo)

```yaml
steps:
  - uses: actions/checkout@v4
    with: { submodules: true, fetch-depth: 0 }
  - uses: dtolnay/rust-toolchain@stable
  - run: cargo build --release
  - run: target/release/your-cli verify --compliance --output compliance.json --schema external/ledger-kernel/schemas/compliance_report.schema.json
  - run: jq -e '.summary.core=="PASS"' compliance.json
```

### C/CMake

```yaml
steps:
  - uses: actions/checkout@v4
    with: { submodules: true, fetch-depth: 0 }
  - run: |
      cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
      cmake --build build --target all
  - run: ./build/bin/your-cli verify --compliance --output compliance.json --schema external/ledger-kernel/schemas/compliance_report.schema.json
  - run: jq -e '.summary.core=="PASS"' compliance.json
```

## 8. Example implementation

See the reference implementation in C, at [libgitledger](https://github.com/flyingrobots/libgitledger).
