---
title: Formal Specification
---

# Formal Specification

This section defines the normative, testable rules for Ledger‑Kernel. Clauses are numbered FS‑x for cross‑reference from the Model (M‑x) and Compliance pages. Wire‑level encodings appear in [Wire Format](/spec/wire-format).

## 1. Data Structures

<a id="fs-1"></a>
### FS‑1 Entry (Abstract)
An Entry SHALL be an immutable record addressable by a collision‑resistant content hash. Conceptually, an Entry comprises:

- `parent` — the hash of the previous Entry in the ledger (or null for genesis)
- `timestamp` — creation time in UTC (see FS‑11)
- `author` — author identity (format per Wire Format)
- `payload` — typed, canonicalized application data
- `attestations[]` — one or more attestations bound to the Entry’s content hash (FS‑2)

An Entry MUST serialize deterministically (FS‑10) and be committed as a conventional Git commit under a namespaced ref (see FS‑8, FS‑12).

<a id="fs-2"></a>
### FS‑2 Attestation (Abstract)
An Attestation SHALL bind a signer identity to an Entry’s content hash using a specified algorithm. At minimum it MUST include:

- `signer` — identity key or fingerprint
- `algorithm` — signature scheme identifier
- `signature` — signature bytes over the Entry’s canonical hash
- `scope` — purpose string (e.g., `append`, `policy`)
- `timestamp` — time the attestation was created (UTC)

Verification MUST succeed with repository‑local material (FS‑6).

<a id="fs-3"></a>
### FS‑3 Policy Result (Abstract)
Policy evaluation SHALL be deterministic and side‑effect free. Its result is a boolean decision and MAY include structured diagnostics:

- `accepted: bool`
- `reasons: string[]` (implementation‑defined)

Policy engines MUST NOT read clocks, randomness, network, or ambient I/O (FS‑9).

## 2. Operations

<a id="fs-4"></a>
### FS‑4 append(R, L, E)
To append, an implementation MUST:

1) Validate Entry (schema + canonicalization) and compute its hash.
2) Verify that `parent == head(L)` (or genesis rules) and that the ref update is fast‑forward (FS‑8).
3) Evaluate all required policies for `(E, state(L))` and obtain acceptance (FS‑3).
4) Verify required attestations bound to `hash(E)` (FS‑2).
5) Commit E under the ledger ref namespace and advance the ref by fast‑forward.

If any step fails, the implementation MUST NOT advance the ref and MUST return an error.

<a id="fs-5"></a>
### FS‑5 replay(R, L)
Replay SHALL fold the deterministic transition function over the ordered Entries (M‑2) from the genesis to head, producing `state(L)`. Replay MUST NOT consult external state.

<a id="fs-6"></a>
### FS‑6 verify(R, L)
Verification SHALL check the entire history of `L` for conformity: ordering, fast‑forward ref evolution, canonical hashes, required attestations, deterministic policy acceptance, and deterministic replay equivalence. Verification MUST be possible using repository‑local data only (no network).

## 3. Determinism & Constraints

<a id="fs-7"></a>
### FS‑7 Append‑Only & Total Order
The set of Entries under the ledger ref SHALL form a single linear chain with no merges or parallel branches. Once committed, Entries MUST NOT be modified or deleted.

<a id="fs-8"></a>
### FS‑8 Fast‑Forward Only (Ref Semantics)
The ledger ref `p` SHALL advance only by fast‑forward such that `Parent(Eᵢ₊₁) = Hash(Eᵢ)`. Non‑FF updates (rebase, force‑push, merge) are forbidden.

<a id="fs-9"></a>
### FS‑9 Policy Determinism
Policy engines SHALL be deterministic. They MUST NOT access monotonic or wall‑clock time, random number generators, network, filesystem, or environment state except for explicitly whitelisted, immutable inputs provided by the host. Given identical inputs, evaluation MUST yield identical outputs.

<a id="fs-10"></a>
### FS‑10 Canonical Serialization & Hashing
Entries and Attestations SHALL serialize to a canonical byte sequence unambiguously (e.g., stable field order, UTF‑8, normalized newlines). The content hash used for identity and signatures MUST be computed over this canonical form. The canonicalization procedure MUST be documented and stable.

<a id="fs-11"></a>
### FS‑11 Temporal Monotonicity
Entry timestamps SHALL be monotonically non‑decreasing relative to their parent. Implementations MAY enforce stricter monotonicity policies via the policy engine.

<a id="fs-12"></a>
### FS‑12 Namespaces & Storage
Ledger data SHALL be stored under a dedicated ref namespace (e.g., `refs/_ledger/<ns>`). Attestations and policies MAY use auxiliary refs under the same namespace as defined in Wire Format. Implementations MUST NOT rely on non‑Git storage to satisfy core verification (FS‑6).

## 4. Errors & Reporting

<a id="fs-13"></a>
### FS‑13 Error Domains
Implementations SHOULD expose structured error domains: `parse`, `canonicalize`, `hash`, `attestation`, `policy`, `ordering`, `ff`, `io`, `internal`.

<a id="fs-14"></a>
### FS‑14 Diagnostics
Verification and append failures SHOULD include machine‑readable diagnostics sufficient to reproduce the decision offline.

## 5. Conformance Notes

::: info Relationship to Model (M‑x)
- FS‑7, FS‑8, FS‑10, FS‑11, FS‑12 substantiate M‑4..M‑6 (invariants) and M‑7 (deterministic replay).
- FS‑3, FS‑9 substantiate M‑9 (policy determinism).
- FS‑6 substantiates M‑8 (offline verification).
:::

## 5.1 FS↔M Mapping

The following table links Model clauses (M‑x) to the normative Formal Spec clauses (FS‑x):

| Model (M‑x) | Summary | Formal Spec (FS‑x) |
| --- | --- | --- |
| M‑1 | Ledger structure (L = (p, E, A, P)) | [FS‑1](#fs-1), [FS‑2](#fs-2), [FS‑3](#fs-3) |
| M‑2 | State and transition, replay as fold | [FS‑5](#fs-5), [FS‑10](#fs-10) |
| M‑3 | Admission predicate V(L,S,E) | [FS‑3](#fs-3), [FS‑4](#fs-4) |
| M‑4 | Append‑only | [FS‑7](#fs-7) |
| M‑5 | Fast‑forward only | [FS‑8](#fs-8) |
| M‑6 | Total order (single chain) | [FS‑7](#fs-7), [FS‑8](#fs-8) |
| M‑7 | Deterministic replay | [FS‑5](#fs-5), [FS‑9](#fs-9), [FS‑10](#fs-10) |
| M‑8 | Offline verify | [FS‑6](#fs-6) |
| M‑9 | Policy determinism | [FS‑3](#fs-3), [FS‑9](#fs-9) |

## 6. References

- [Model](/spec/model)
- [Wire Format](/spec/wire-format)
