# Changelog

## v0.1.0 (proposed)

- Spec spine: Model (M‑1..M‑9), Formal Spec (FS‑1..FS‑14)
- Wire Format: JSON canonical profile (+ optional CBOR profile), BLAKE3‑256 id, domain‑separated signing input
- Compliance: levels (Core/Policy/WASM), checks C‑1..C‑5, report schema
- Schemas: entry, attestation, policy_result, compliance_report (+ aliases)
- Vectors: Python/Rust/Go canonicalization tools; JSON golden vector; CI matrix that fails on divergence
- Orchestrator: minimal TOML‑driven runner that emits compliance.json and validates against schema
- WASM Policy ABI: deterministic host interface and constraints
- Implementers Guide and CLI harness docs

