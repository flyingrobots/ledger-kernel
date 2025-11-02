---
title: State‑Transition Model
---

# State‑Transition Model

This page formalizes the ledger as a deterministic state machine over Git commits recorded under a namespaced ref. It follows the same terminology as the repository’s MODEL.md and adds numbered clauses (M‑x) for conformance.

> See also: [Model Source](/spec/model-source) for the unannotated canonical text from `MODEL.md`.

## 1. Ledger Objects and Notation

::: info M‑1 (Ledger Structure)
A ledger L SHALL be the tuple (p, E, A, P), where p is a Git ref, E is a totally ordered sequence of entries (Git commits under p), A is the set of attestations bound to entries, and P is the active policy set. Each entry MUST be a conventional Git commit recorded under p. See Formal Spec (FS‑1…FS‑3).
:::

- Repository R is a standard Git repository (objects + refs).
- A ledger entry is a Git commit C recorded under a ledger ref p (e.g., `refs/_ledger/<namespace>`) with payload and metadata encoded per the wire format.
- A ledger is L = (p, E, A, P):
  - p: persistent ref path
  - E = ⟨E₀, E₁, …, Eₙ⟩: single, linear sequence of entries (Git ancestry under p)
  - A: attestations (signatures, proofs) bound to entries
  - P: policy set used to admit entries

The head of L is `Hash(Eₙ) = R[p]`.

## 2. State and Transition Function

::: info M‑2 (State and Transition)
The ledger state space S SHALL admit a pure, deterministic transition function `T: S × Entry → S` with `S₀ = ∅` and `Sₙ = foldl(T, S₀, E)`.
:::

Replay is a fold over the entry sequence:

- `Sₙ = foldl(T, S₀, E) = T(T(…T(S₀, E₀)…), Eₙ)`

Intuition: given a current state `Sᵢ` and the next entry `Eᵢ₊₁`, produce the next state `Sᵢ₊₁ = T(Sᵢ, Eᵢ₊₁)`.

## 3. Admission and Validity

::: info M‑3 (Admission Predicate)
An entry `Eᵢ` is admissible at state `Sᵢ` iff `V(L,Sᵢ,Eᵢ) = true`, where V includes:
- fast‑forward update of ref `p` (no rebase/merge under `p`),
- required attestations for `Eᵢ` are valid and bound to its content,
- all policies in `P` deterministically accept `Eᵢ` given `Sᵢ`. See FS‑3, FS‑4.
:::

If V fails, `Eᵢ` MUST NOT advance `p` and MUST be rejected.

## 4. Invariants

::: info M‑4 (Append‑Only)
Once recorded, entries MUST NOT be modified or deleted.
:::

::: info M‑5 (Fast‑Forward Only)
The ref `p` MUST only advance by fast‑forward: `Parent(Eᵢ₊₁) = Hash(Eᵢ)`. No rebases, merges, or non‑linear histories under `p`.
:::

::: info M‑6 (Total Order)
`E` MUST be a single linear chain (no parallel branches or merge commits under `p`).
:::

These invariants ensure a unique, monotonic history suitable for replay.

## 5. Deterministic Replay

::: info M‑7 (Deterministic Replay)
For any ledgers with identical `E` and identical applicable `P` and encodings, replay SHALL produce identical final states:
`E¹ = E² ⇒ foldl(T, S₀, E¹) = foldl(T, S₀, E²)`.
Implementations MUST exclude nondeterminism on the kernel path (wall‑clock time, randomness, external I/O). See FS‑5.
:::

Why it holds:
- `T` is pure and deterministic by construction.
- `E` is totally ordered and append‑only; ref evolution is FF‑only.
- Therefore the fold across `E` is a deterministic computation.

## 6. Policy and Attestation

- Policy engine evaluations MUST be deterministic (e.g., sandboxed WASM with fixed inputs only and no ambient time/IO).
- Attestations are verified from repository content; network access is not required.

::: info M‑9 (Policy Determinism)
Policy evaluation MUST be deterministic (e.g., WASM sandbox with fixed inputs and no ambient time). See FS‑3.
:::

## 7. Conformance (Verification Without Network)

::: info M‑8 (Offline Verify)
Implementations MUST verify and replay using repository data alone; network access SHALL NOT be required for core verification. See FS‑6.
:::

## 8. References

- [Formal Spec](/spec/formal-spec) — numbered clauses FS‑1..N (data structures, operations, constraints)
- [Wire Format](/spec/wire-format) — JSON schemas, attestation encodings, canonical serialization rules

