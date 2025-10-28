---
Author: J. Kirby Ross <james@flyingrobots.dev> (https://github.com/flyingrobots) 
Created: 2025-10-27
License: MIT
Scope: This document defines the minimal, requisite semantics and invariants that a Git-native ledger implementation must satisfy to be considered compliant.
Status: Draft
Summary: Defines the invariants, operations, and compliance requirements for a Git-native append-only ledger.
Version: 0.1.0 
---

# **Ledger-Kernel Specification**

## 1.0 Purpose

The fundamental purpose of the **Ledger-Kernel** is to provide a universal, abstract model for an append-only, cryptographically attested state machine within a standard Git repository.

It is critical to establish that this document does not constitute an implementation. Rather, it defines the formal contract and set of guarantees that any software implementation (such as the reference implementation, `libgitledger`) must uphold to be designated as kernel-compatible.

## 2.0 Formal Terminology

The following terms are defined for the purpose of this specification:

$Repository (R)$: A Git object store and its associated reference namespace.

$Ledger (L)$: A monotonic, ordered sequence of entries, the history of which is stored under a dedicated Git reference (ref) path.

$Entry (E)$: An immutable, atomic record. Each Entry contains a data payload, associated metadata, and one or more attestations.

$Policy (P)$: A deterministic rule set, or pure function, that algorithmically determines whether a candidate Entry may be appended to the Ledger or is considered valid during verification.

$Attestation (A)$: A cryptographic statement, such as a digital signature, that binds a signer's identity to a specific Entry hash, thereby proving authenticity or approval.

$Replay$: The computational process of deterministically reconstructing a ledger’s derived state by iteratively processing its Entries from the genesis Entry to the current head.

## 3.0 Core Operations

A compliant implementation must provide a set of core operations that adhere to the following functional definitions:

$append(R, L, E)$: This operation adds a new $Entry(E)$ to a given $Ledger(L)$ within $Repository(R)$. This operation **MUST** be executed as a Git fast-forward commit.

$attest(R, L, E, A)$: This operation associates an additional $Attestation(A)$ with an existing $Entry(E)$ in $Ledger(L)$, typically to add supplementary proofs of authenticity or approval.

$evaluate(R, L, E, P)$: This operation applies a specific Policy `P` to a proposed candidate $Entry(E)$ in the context of $Ledger(L)$. This function **MUST** be deterministic and return a boolean result indicating the Entry's validity.
 
$replay(R, L)$: This operation iteratively applies all Entries in the defined sequence of $Ledger(L)$ to produce the current, derived state of the system.

$verify(R, L)$ This operation validates the entire history of $Ledger(L)$, confirming that all Entries and their associated Attestations adhere to the full set of kernel invariants.

## 4.0 Core Invariants

The model’s integrity depends on seven non-negotiable properties.

It must remain **append-only**, meaning entries, once committed, can never be altered or removed—new state emerges only from additional entries.

All updates must be **fast-forward only**; rebases or force pushes are forbidden.

Replay operations must be **deterministic**, yielding identical state whenever identical sequences are processed.

Entries must be **authenticated** through cryptographic verification of their content hashes and attestations.

Every append must observe **policy enforcement**, allowing inclusion only when all required policies evaluate to true within the same execution context.

Timestamps must satisfy **temporal monotonicity**, each new entry’s time being greater than or equal to that of its parent.

Finally, **namespace isolation** requires that each ledger’s validity depend solely on its own references, never on external ones.

## 5.0 Data Model

This specification defines the canonical, abstract structure of ledger components.

### 5.1 Canonical Entry Schema

An Entry must be serializable to a canonical form. While JSON is used for illustrative purposes, a compliant implementation must define a deterministic, byte-for-byte serialization. The conceptual schema includes the following fields:

- `id`: A unique identifier, typically a cryptographic hash (e.g., BLAKE3) of the canonicalized Entry.
- `parent`: The `id` of the preceding Entry, forming the ledger's chain.
- `timestamp`: An ISO 8601 string representing the time of creation (e.g., "2025-01-01T00:00:00Z").
- `author`: An identifier for the Entry's creator (e.g., a GPG fingerprint).
- `payload`: A container for the Entry's data, including a `type` (e.g., "text/json") and the `data` itself.
- `attestations`: An array of one or more serialized Attestation signatures.

### 5.2 Canonical Attestation Schema

An Attestation is a discrete object, conceptually represented with the following fields:

- `signer`: The identity of the attesting party (e.g., a GPG fingerprint).
- `algorithm`: The signature algorithm used (e.g., "ed25519").
- `signature`: The Base64-encoded signature data.
- `scope`: A string defining the purpose of the attestation (e.g., "append", "policy", or a custom scope).
- `timestamp`: The ISO 8601 time the attestation was generated.

### 5.3 Policy Evaluation Context

A Policy function's execution environment must be strictly constrained to ensure determinism (per Invariant 4.3).

The policy has read-only access exclusively to the following:

1. The full data of the candidate Entry being evaluated.
2. The full data of the ledger’s previous (i.e., parent) Entry.
3. A limited set of repository metadata.
4. A set of environment variables that have been explicitly whitelisted by the system's configuration.

All functions utilized within a policy evaluation must be pure and deterministic. They must not rely on network access, non-deterministic system calls, or any other external state.

## 6.0 Compliance Requirements

A conformant implementation of the Ledger-Kernel specification **MUST** satisfy all of the following requirements:

1. It must enforce all seven invariants as enumerated in §4.
2. It must store Entries as immutable objects (such as Git 'blob' or 'commit' objects) that are addressable by a collision-resistant cryptographic hash.
3. It must provide the necessary mechanisms for a third party to independently verify all cryptographic Attestations.
4. It must define and utilize a deterministic serialization and hashing procedure for all data structures to ensure reproducible IDs and signatures.
5. It must successfully pass all tests contained within the official compliance suite (located at `tests/compliance/`).

## 7.0 Normative Reference Layout

This specification defines a normative, or standard, directory layout within the Git reference namespace (i.e., under `refs/`). A compliant implementation must adhere to this structure:

- `refs/_ledger/`: The root namespace for all kernel-related data.
- `refs/_ledger/<namespace>/current`: A ref pointing to the fast-forward-only head (the most recent Entry) of a specific ledger namespace.
- `refs/_ledger/<namespace>/attest/`: A namespace reserved for storing supplementary attestation data (e.g., as Git notes).
- `refs/_ledger/<namespace>/policy/`: A namespace for refs pointing to the optional, versioned policies governing the ledger.
- `refs/_ledger/_meta/`: A reserved namespace for metadata concerning the ledger system itself.
- `refs/_ledger/_meta/version`: A ref or object indicating the compliant kernel version.
- `refs/_ledger/_meta/config.json`: A ref or object pointing to the system's configuration.

## 8.0 Extensibility

Implementations **MAY** introduce optional, extended features, provided that these features do not, under any circumstances, violate the core invariants detailed in §4.

Acceptable enhancements include new attestation formats that support multi-signature or quorum approval, integration of external deterministic policy engines such as a WASM runtime for `evaluate()`, and optional non-Git replication transports for remote synchronization.  

These remain subordinate to the canonical model defined here.

## 9.0 Compliance Testing

Implementations demonstrate compatibility by executing the official test suite, typically via make test.  The suite verifies deterministic replay, confirms that append-only semantics are enforced, validates all cryptographic attestations, and checks that policy evaluation behaves correctly and reproducibly across environments.

---

## 10.0 Versioning

This kernel specification adheres to Semantic Versioning. Any formal change to this document that alters, adds to, or removes any of the defined invariants requires an increment of the MAJOR version number.

---

## 11.0 References

This specification is informed by and related to the following external works:

1.  Chacon, S., & Straub, B. (2014). Git Internals. In *Pro Git* (2nd ed.). Apress.
2.  Ledger. (n.d.). *RFC 001: Cryptographic Attestations for SCM*. Retrieved from **[https://ledger.website/rfc-001.html](https://ledger.website/rfc-001.html)**
3.  Reproducible Builds Project. (n.d.). **[Deterministic Build Systems](https://reproducible-builds.org/docs/deterministic-build-systems/)**. Retrieved October 27, 2025, from https://reproducible-builds.org/docs/deterministic-build-systems/
