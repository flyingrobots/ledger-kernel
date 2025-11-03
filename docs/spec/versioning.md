---
title: Versioning & Releases
---

# Versioning & Releases

This document defines how the Ledger‑Kernel spec, schemas, and vectors are versioned and released.

## 1. Semantic Versioning

The spec uses SemVer: `MAJOR.MINOR.PATCH`.

- MAJOR — Breaking changes to normative clauses (FS/M) that alter conformance semantics or the data model.
- MINOR — Additive features: new clauses, optional checks, additional profiles (e.g., CBOR), new informative sections.
- PATCH — Clarifications, typos, non‑normative doc changes, additional vectors that do not change semantics.

## 2. v0.1.0 (initial tag)

Scope:
- Model (M‑1…M‑9), Formal Spec (FS‑1…FS‑14)
- Wire Format (JSON canonical profile); optional CBOR profile (cbor1)
- Compliance (levels Core/Policy/WASM; checks C‑1…C‑5; report schema)
- Schemas: entry, attestation, policy_result, compliance_report
- Vectors: canonicalization tools (Py/Rust/Go) and a golden entry vector; CI matrices

Artifacts:
- Tag `v0.1.0`
- `schemas/` as released assets
- `tests/vectors/` + `scripts/vectors/` tools
- `scripts/harness/` orchestrator
- CHANGELOG.md

## 3. Pinning Guidance for Implementations

- Add this repo as a submodule at `external/ledger-kernel` pinned to a tag (e.g., v0.1.0).
- Reference schemas from the submodule path.
- Run vector CI (JSON and, if applicable, CBOR) to catch canonicalization drift.

## 4. Migration Policy

- MINOR bumps: re-run suites; implement new optional checks when feasible.
- MAJOR bumps: a migration table will map old FS/M to new clauses; new vectors will be published; dual‑format periods (e.g., JSON↔CBOR) will be specified with profile flags (e.g., `LK-Profile`).

