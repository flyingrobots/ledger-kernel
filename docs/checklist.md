# Ledger-Kernel 1.0.0 — Execution Checklist

Generated from GitHub Issues on 2025-10-29 17:26 UTC.

## Phase Order (Hard Dependencies)
- M0 → M1 → M2 → M3 → M4 → M5 → M6 → v1.0.0

## M0 Repo Hygiene

### Next
- [ ] [Rename NOTICE.m → NOTICE.md](https://github.com/flyingrobots/ledger-kernel/issues/13) (#13)
- [ ] [Fix README tables and stray hyphens](https://github.com/flyingrobots/ledger-kernel/issues/14) (#14)
- [ ] [Fix typo: tests/fixtures/miniaml_repo → minimal_repo](https://github.com/flyingrobots/ledger-kernel/issues/15) (#15)
- [ ] [Align test filenames or COMPLIANCE to naming](https://github.com/flyingrobots/ledger-kernel/issues/16) (#16)
- [ ] [Logo asset path: add image or remove from README](https://github.com/flyingrobots/ledger-kernel/issues/17) (#17)

## M1 Norms

### Next
- [ ] [Spec: Proofs storage modes + defaults + paths](https://github.com/flyingrobots/ledger-kernel/issues/18) (#18)
- [ ] [Spec: Attestation storage modes + resolver](https://github.com/flyingrobots/ledger-kernel/issues/19) (#19)
- [ ] [Config: _meta/config.json keys for modes](https://github.com/flyingrobots/ledger-kernel/issues/20) (#20)
- [ ] [Spec: Hash IDs/digests (BLAKE3 + SHA256 mirror)](https://github.com/flyingrobots/ledger-kernel/issues/21) (#21)
- [ ] [Spec: Policy determinism profile (hostless WASM)](https://github.com/flyingrobots/ledger-kernel/issues/22) (#22)
- [ ] [Spec: Timestamp rules (ISO-8601 UTC; monotonic)](https://github.com/flyingrobots/ledger-kernel/issues/23) (#23)
- [ ] [Spec: Canonical JSON (sorted keys; no floats)](https://github.com/flyingrobots/ledger-kernel/issues/24) (#24)
- [ ] [Spec: Proofs compaction + snapshot manifest](https://github.com/flyingrobots/ledger-kernel/issues/25) (#25)
- [ ] [Docs: Update ref layout diagrams (modes + compaction)](https://github.com/flyingrobots/ledger-kernel/issues/26) (#26)

## M2 Spec Freeze RC

### Next
- [ ] [SPEC.md normative pass (MUST/SHOULD/MAY) & remove markers](https://github.com/flyingrobots/ledger-kernel/issues/27) (#27) ⛓ blocked (10)
- [ ] [MODEL.md formulas + plain-text fallbacks](https://github.com/flyingrobots/ledger-kernel/issues/28) (#28) ⛓ blocked (10)
- [ ] [REFERENCE.md align IDs/digests + config keys + errors](https://github.com/flyingrobots/ledger-kernel/issues/29) (#29) ⛓ blocked (10)
- [ ] [ARCHITECTURE.md sync with modes + compaction](https://github.com/flyingrobots/ledger-kernel/issues/30) (#30) ⛓ blocked (10)
- [ ] [COMPLIANCE.md: mode selection + quorum (Core vs Extended)](https://github.com/flyingrobots/ledger-kernel/issues/31) (#31) ⛓ blocked (10)

## M3 Schemas+Examples

### Next
- [ ] [Schema: schemas/entry.json (canonical fields; no floats)](https://github.com/flyingrobots/ledger-kernel/issues/32) (#32)
- [ ] [Schema: schemas/attest.json (mode-agnostic)](https://github.com/flyingrobots/ledger-kernel/issues/33) (#33)
- [ ] [Schema: schemas/proof.json (append/attest/policy/replay + snapshot)](https://github.com/flyingrobots/ledger-kernel/issues/34) (#34)
- [ ] [Schema: schemas/policy.json (metadata + ABI)](https://github.com/flyingrobots/ledger-kernel/issues/35) (#35)
- [ ] [Script: scripts/validate_schemas.sh (ajv/spectral)](https://github.com/flyingrobots/ledger-kernel/issues/36) (#36)
- [ ] [REFERENCE.md: schema usage + canonicalization notes](https://github.com/flyingrobots/ledger-kernel/issues/37) (#37)
- [ ] [Examples: proofs branch mode (end-to-end)](https://github.com/flyingrobots/ledger-kernel/issues/38) (#38)
- [ ] [Examples: proofs notes mode](https://github.com/flyingrobots/ledger-kernel/issues/39) (#39)
- [ ] [Examples: proofs private mode](https://github.com/flyingrobots/ledger-kernel/issues/40) (#40)
- [ ] [Examples: attestation via commit signature](https://github.com/flyingrobots/ledger-kernel/issues/41) (#41)
- [ ] [Examples: attestation via notes and via attestation branch](https://github.com/flyingrobots/ledger-kernel/issues/42) (#42)
- [ ] [Walkthrough: examples/replay_invariants.md](https://github.com/flyingrobots/ledger-kernel/issues/43) (#43)

## M4 Compliance MVP

### Next
- [ ] [Harness: tests/harness/run_tests.sh (mode-aware)](https://github.com/flyingrobots/ledger-kernel/issues/44) (#44) ⛓ blocked (7)
- [ ] [Verifier: tests/harness/verify_proofs.py (mode-aware)](https://github.com/flyingrobots/ledger-kernel/issues/45) (#45) ⛓ blocked (7)
- [ ] [Compliance: Fixture 01 — Append-Only: attempt modify/delete → reject](https://github.com/flyingrobots/ledger-kernel/issues/46) (#46) ⛓ blocked (7)
- [ ] [Compliance: Fixture 02 — Fast-Forward: non-ancestor commit → reject](https://github.com/flyingrobots/ledger-kernel/issues/47) (#47) ⛓ blocked (7)
- [ ] [Compliance: Fixture 03 — Deterministic Replay: two runs → identical state_b3](https://github.com/flyingrobots/ledger-kernel/issues/48) (#48) ⛓ blocked (7)
- [ ] [Compliance: Fixture 04 — Attestation Verification: tamper → invalid](https://github.com/flyingrobots/ledger-kernel/issues/49) (#49) ⛓ blocked (7)
- [ ] [Compliance: Fixture 05 — Policy Enforcement: WASM policy false → reject](https://github.com/flyingrobots/ledger-kernel/issues/50) (#50) ⛓ blocked (7)
- [ ] [Compliance: Fixture 06 — Temporal Monotonicity: back-dated → reject](https://github.com/flyingrobots/ledger-kernel/issues/51) (#51) ⛓ blocked (7)
- [ ] [Compliance: Fixture 07 — Namespace Isolation: cross-ref pollution prevented](https://github.com/flyingrobots/ledger-kernel/issues/52) (#52) ⛓ blocked (7)
- [ ] [Compliance: Fixture 08 — Equivalence: identical sequences → equal states](https://github.com/flyingrobots/ledger-kernel/issues/53) (#53) ⛓ blocked (7)
- [ ] [Extended: Quorum policy 2-of-3 + fixtures](https://github.com/flyingrobots/ledger-kernel/issues/54) (#54) ⛓ blocked (7)
- [ ] [Extended: Verifier checks quorum result in proofs](https://github.com/flyingrobots/ledger-kernel/issues/55) (#55) ⛓ blocked (7)

## M5 Docs+CI

### Next
- [ ] [VitePress: scaffold site (config + index + nav)](https://github.com/flyingrobots/ledger-kernel/issues/56) (#56)
- [ ] [VitePress: convert admonitions + mermaid strategy](https://github.com/flyingrobots/ledger-kernel/issues/57) (#57)
- [ ] [VitePress: Modes & Decisions pages](https://github.com/flyingrobots/ledger-kernel/issues/58) (#58)
- [ ] [VitePress: GH Pages workflow](https://github.com/flyingrobots/ledger-kernel/issues/59) (#59)
- [ ] [README cleanup and site link](https://github.com/flyingrobots/ledger-kernel/issues/60) (#60)
- [ ] [CI: markdown lint + spell check](https://github.com/flyingrobots/ledger-kernel/issues/61) (#61)
- [ ] [CI: link checker](https://github.com/flyingrobots/ledger-kernel/issues/62) (#62)
- [ ] [CI: schema validation job](https://github.com/flyingrobots/ledger-kernel/issues/63) (#63)
- [ ] [CI: VitePress build check](https://github.com/flyingrobots/ledger-kernel/issues/64) (#64)
- [ ] [CI: Mermaid render or fallback images](https://github.com/flyingrobots/ledger-kernel/issues/65) (#65)

## M6 Governance+Security

### Next
- [ ] [CHANGELOG.md (0.1.0→1.0.0)](https://github.com/flyingrobots/ledger-kernel/issues/66) (#66)
- [ ] [Version negotiation + _meta/version guidance](https://github.com/flyingrobots/ledger-kernel/issues/67) (#67)
- [ ] [Release process doc (tagging, signing, publish)](https://github.com/flyingrobots/ledger-kernel/issues/68) (#68)
- [ ] [Spec freeze process (exclusive window)](https://github.com/flyingrobots/ledger-kernel/issues/69) (#69)
- [ ] [SECURITY.md (contact, timelines)](https://github.com/flyingrobots/ledger-kernel/issues/70) (#70)
- [ ] [Threat model doc](https://github.com/flyingrobots/ledger-kernel/issues/71) (#71)
- [ ] [Key guidance (Ed25519, rotation, trust roots, quorum)](https://github.com/flyingrobots/ledger-kernel/issues/72) (#72)
- [ ] [CONTRIBUTING.md](https://github.com/flyingrobots/ledger-kernel/issues/73) (#73)
- [ ] [CODE_OF_CONDUCT.md](https://github.com/flyingrobots/ledger-kernel/issues/74) (#74)
- [ ] [Issue templates (Bug, Spec Change, Docs, Compliance)](https://github.com/flyingrobots/ledger-kernel/issues/75) (#75)
- [ ] [PR template (schema validates, links checked, decisions referenced)](https://github.com/flyingrobots/ledger-kernel/issues/76) (#76)
- [ ] [Labels guide (Labels.md)](https://github.com/flyingrobots/ledger-kernel/issues/77) (#77)

