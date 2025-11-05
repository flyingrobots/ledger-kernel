---
Author: J. Kirby Ross <james@flyingrobots.dev> (https://github.com/flyingrobots) 
Created: 2025-10-27
License: MIT
Status: Draft
Summary: Defines the conformance criteria and test methodology for verifying that an implementation satisfies the Ledger-Kernel Specification and Model.
Version: 0.1.0 
---

# ✅ Ledger-Kernel COMPLIANCE SUITE

## 1. Purpose

The compliance suite ensures that any implementation of the **Ledger-Kernel** (e.g., `libgitledger`, `ledger-core-rust`, `ledger-js`) adheres to the invariants, semantics, and deterministic behavior defined in the [Specification](/spec/) and [Model](/spec/model).

A compliant implementation must **pass all mandatory tests** and **expose proofs or logs**
demonstrating correctness.

---

## 2. Structure

```bash
tests/
├── compliance/
│ ├── 01_append_only.yaml
│ ├── 02_fast_forward.yaml
│ ├── 03_deterministic_replay.yaml
│ ├── 04_attestation_verification.yaml
│ ├── 05_policy_enforcement.yaml
│ ├── 06_temporal_monotonicity.yaml
│ ├── 07_namespace_isolation.yaml
│ └── 08_equivalence.yaml
├── fixtures/
│ ├── minimal_repo/
│ ├── multi_sig/
│ ├── fork_conflict/
│ └── replay_example/
└── harness/
├── run_tests.sh
├── compare_states.py
└── verify_proofs.py
```

Each `.yaml` file describes:

- **Goal:** what invariant is tested  
- **Input:** pre-state, entries, and policies  
- **Expected:** resulting state or error condition  

---

## 3. Test Categories

### 3.1 Core Invariants

| **ID** | **Name** | **Description** | **Pass Criteria** |
|----|------|--------------|----------------|
| 01 | `Append-Only` | Attempt to remove/modify entries | Operation rejected; history intact |
| 02 | `Fast-Forward` | Attempt non-ancestor commit | Rejected; ref unchanged |
| 03 | `Deterministic Replay` | Replay same ledger twice | Identical state hashes |
| 04 | `Authenticated Entries` | Tamper with attestation | Verification fails deterministically |
| 05 | `Policy Enforcement` | Submit invalid entry per policy | Rejected with reproducible error |
| 06 | `Temporal Monotonicity` | Back-dated entry | Rejected or quarantined |
| 07 | `Namespace Isolation` | Cross-ref pollution | No cross-ledger contamination |
| 08 | `Ledger Equivalence` | Compare identical sequences | `Replay(L1)==Replay(L2)` |

---

## 4. Extended Tests

### 4.1 Multi-Sig Attestations

Ensure quorum rules (e.g., N-of-M signatures) are enforced.

### 4.2 Policy Composition

Test AND/OR composition of multiple policies for deterministic outcome.

### 4.3 Replay Under Failure

Simulate interrupted append, ensure replay recovers consistent state.

### 4.4 Cross-Language Determinism

Feed identical fixtures into two different implementations; verify identical
state digests (`blake3` or `sha256`).

---

## 5. Proof Artifacts

Implementations must produce *proof files* during testing:

| **Proof** | **Format** | **Contents** |
|--------|---------|-----------|
| `append.proof.json` | JSON | parent hash, entry hash, ref update |
| `attest.proof.json` | JSON | signer, signature, verification result |
| +`policy.proof.json` | JSON | policy name, result, evaluation trace |
| `replay.proof.json` | JSON | input hashes, resulting state hash |

A verifier script (`verify_proofs.py`) recomputes and validates these proofs.

---

## 6. Determinism Audit

For each implementation:

1. Run all fixtures with random seeds suppressed.  
2. Record resulting state digests.  
3. Re-run tests in a clean environment.  
4. **Pass** if all digests are identical.

```bash
$ make determinism
> All 45 tests reproducible ✔
```

---

## 7. Error Taxonomy

Implementations must emit standardized error codes:

| Code | Name | Meaning |
|------|------|---------|
| `E_APPEND_REJECTED` | Append Rejected | Append violates invariants |
| `E_SIG_INVALID` | Signature Invalid | Attestation verification failed |
| `E_POLICY_FAIL` | Policy Failed | Policy evaluation false |
| `E_REPLAY_MISMATCH` | Replay Mismatch | Non-deterministic replay |
| `E_TEMPORAL_ORDER` | Temporal Order | Timestamp regression |
| `E_NAMESPACE` | Namespace Conflict | Cross-ledger conflict |

This allows cross-implementation comparison of failure semantics.

---

## 8. Compliance Scoring

| Level | Requirements |
|-------|-------------|
| Core | Pass 01-08 tests |
| Extended | Pass multi-sig, policy composition, and replay-failure tests |
| Certified | Provide reproducible proofs and determinism audit logs |
| Verified | Independently reviewed and cryptographically attested results |

Implementations **MAY** publish a signed compliance report under:

```bash
refs/_ledger/_meta/compliance/<version>.json
```

---

## 9. Reference Harness

`harness/run_tests.sh` orchestrates the suite:

```bash
#!/usr/bin/env bash
set -euo pipefail
impl=$1
for t in tests/compliance/*.yaml; do
  echo "Running $t"
  $impl --verify $t
done
```

A common Python or Go verifier can be provided for convenience.

---

## 10. Reproducibility Envelope

All fixtures and results should be hash-locked:

```bash
fixtures/
  replay_example/
    entry_0.json
    entry_1.json
    result_state.json
  manifest.yaml
  blake3.manifest
```

This ensures every test is reproducible down to byte order.

---

## 11. Publishing Compliance

Each implementation should publish:

- `COMPLIANCE-REPORT.json`
- `MANIFEST.b3sum`
- `VERIFIER-SIGNATURE.asc`

The report includes version, platform, test summary, and digests.

---

## 12. Future Work
- Property-based generator for randomized append/replay sequences
- Integration with CI/CD to auto-validate pull requests
- Optional differential testing between implementations
