---
Author: J. Kirby Ross <james@flyingrobots.dev> (https://github.com/flyingrobots) 
Created: 2025-10-27
License: MIT
Scope: This document defines the minimal, requisite semantics and invariants that a Git-native ledger implementation must satisfy to be considered compliant.
Status: Draft
Summary: Defines the invariants, operations, and compliance requirements for a Git-native append-only ledger.
Version: 0.1.0 
---

# **A Formal State-Transition Model for a Git-Native Verifiable Ledger**

## Abstract

We present a formal state-transition model for a verifiable ledger kernel operating natively on a Git-based Directed Acyclic Graph (DAG). The model defines a ledger as a totally ordered sequence of entries, where each entry represents an atomic state transition. We formalize the system's core components: a pure state transition function $\mathcal{T}$, a constraint-based policy engine $\mathcal{P}$, and a cryptographic attestation mechanism $\mathcal{A}$. The central thesis of our model is the guarantee of **deterministic replayability**, where the ledger's final state is a pure function of its entry-set. This formalism provides a verifiable foundation for trusted, distributed systems, such as software supply chain attestation or decentralized registries.

---

## 1. Introduction

The Git object model, fundamentally a content-addressed Directed Acyclic Graph (DAG), provides a robust mechanism for tracking provenance. However, its inherent support for branching and non-linear histories complicates its use as a linear, append-only ledger. This paper introduces a formal model that superimposes a **totally ordered state machine** onto the Git DAG. We achieve this by constraining a specific Git reference (ref) to a fast-forward-only commit history, where each commit constitutes a **ledger entry** ($\mathcal{E}$). This model establishes the semantic bridge between low-level Git objects and high-level, verifiable ledger state transitions, enabling deterministic replay and cryptographic verification of the ledger's history and state.

---

## 2. Formal Model Definition

Let a Git repository be a tuple $\mathcal{R} = (\mathcal{O}, \mathcal{R_{efs}})$, where $\mathcal{O}$ is a content-addressed object store (a set of Git objects) and $\mathcal{R_{efs}}$ is a mapping from reference paths to commit identifiers (hashes).

We define a **Ledger Entry**, $\mathcal{E}$, as a commit object $C \in \mathcal{O}$ that adheres to a specific data schema (e.g., contains `/_ledger/entry.json` and associated attestations).

We define a Ledger, $\mathcal{L}$, as a tuple:

$$
\mathcal{L} = (p, \mathbf{E}, \mathcal{A}, \mathcal{P})
$$

where:

- $p$ is the persistent reference path (e.g., `refs/heads/main-ledger`) in $\mathcal{R_{efs}}$.
- $\mathbf{E} = \langle \mathcal{E}_0, \mathcal{E}_1, \dots, \mathcal{E}_n \rangle$ is a **totally ordered sequence** of ledger entries. This ordering is strictly enforced by the commit ancestry relation under $p$, s.t. $\text{Parent}(\mathcal{E}_{i+1}) = \text{Hash}(\mathcal{E}_i)$.
- $\mathcal{A}$ is the set of all attestations, where each $\mathcal{A}_k \in \mathcal{A}$ is cryptographically bound to a specific entry $\mathcal{E}_i \in \mathbf{E}$.
- $\mathcal{P}$ is a set of policies applicable to $\mathcal{L}$.

The _head_ of the ledger $\mathcal{L}$ corresponds to the commit hash $\text{Hash}(\mathcal{E}_n)$, which is the value of $\mathcal{R_{efs}}[p]$.

---

## 3. The State Transition System

The ledger's semantics are defined by a deterministic state transition system.

Let $\mathcal{S}$ be the set of all possible ledger states. We define the initial state as the empty set: $\mathcal{S}_0 = \emptyset$.

We define a pure, deterministic state transition function $\mathcal{T}$:

$$
\mathcal{T} : \mathcal{S} \times \mathcal{E} \to \mathcal{S}
$$

Given a current state $\mathcal{S}_i$ (derived from entry $\mathcal{E}_i$), the subsequent state $\mathcal{S}_{i+1}$ is produced by applying the next entry $\mathcal{E}_{i+1}$:

$$
\mathcal{S}_{i+1} = \mathcal{T}(\mathcal{S}_i, \mathcal{E}_{i+1})
$$

The function $\mathcal{T}$ must be **deterministic** and **pure**; it must produce an identical output state $\mathcal{S}_{i+1}$ given identical inputs $(\mathcal{S}_i, \mathcal{E}_{i+1})$, with no reliance on external I/O, network state, or stochastic processes.

### 3.1. State Re-computation (Replay)

The complete state $\mathcal{S}_n$ of a ledger $\mathcal{L}$ with $n$ entries is the result of a functional fold (or reduction) over the entry sequence $\mathbf{E}$:

$$
\mathcal{S}_n = \text{foldl}(\mathcal{T}, \mathcal{S}_0, \mathbf{E})
$$

Recursively, this is defined as:

- $\text{Replay}(\langle \rangle) = \mathcal{S}_0$
- $\text{Replay}(\langle \mathcal{E}_0, \dots, \mathcal{E}_i \rangle) = \mathcal{T}(\text{Replay}(\langle \mathcal{E}_0, \dots, \mathcal{E}_{i-1} \rangle), \mathcal{E}_i)$

This property is the foundation of the system's verifiability.

---

## 4. Transition Validity

> [!important] For a new entry $\mathcal{E}_{i+1}$ to be appended to the ledger at state $\mathcal{S}_i$, a global **validity predicate** $\mathcal{V}$ must evaluate to `true`.
>
> $$
> \mathcal{V}(\mathcal{E}_{i+1}, \mathcal{E}_i, \mathcal{S}_i, \mathcal{P}) \to \{\text{true}, \text{false}\}
> $$

The predicate $\mathcal{V}$ is the logical conjunction of the following constraints:

> [!important] 1. Ancestry Constraint: The entry must maintain the fast-forward chain.
>
> $$
> \text{ParentHash}(\mathcal{E}_{i+1}) \equiv \text{Hash}(\mathcal{E}_i)
> $$

> [!important] 2. Temporal Monotonicity: The entry's timestamp must be non-decreasing.
>
> $$
> \text{Timestamp}(\mathcal{E}_{i+1}) \geq \text{Timestamp}(\mathcal{E}_i)
> $$

> [!important] 1. Policy Adherence: The entry must satisfy all active policies $\mathcal{P}_k \in \mathcal{P}$, evaluated against the current state $\mathcal{S}_i$. (See §5).
> $$
> \mathcal{P}_{\text{all}}(\mathcal{E}_xt{attest}}(\mathcal{A}_i)
> $$

> [!important] Attestation Validity: All attestations $\mathcal{A}_k$ attached to $\mathcal{E}_{i+1}$ must be cryptographically valid. (See §6).
> $$
> \text{Timestamp}(\mathcal{E}_{i+1}) \equiv \text{true}
> $$
> If $\mathcal{V}$ fails, the transition is rejected, and the entry $\mathcal{E}_{i+1}$ is not appended to the ledger $\mathcal{L}$.

---

### **5. Policy as a State Constraint**

A policy is a pure function (a predicate) that constrains valid transitions.
$$
\mathcal{P}_i)
$$
Policies are executed _before_ the state transition function $\mathcal{T}$ is applied. They are evaluated using the candidate entry ($\mathcal{E}_{i+1}$) and the previous state ($\mathcal{S}_i$).

Policies are composable, typically via logical conjunction:
$$
\mathcal{P}_{\text{all}}(\mathcal{E}, \mathcal{S}) = \bigwedge_{k \in \mathcal{P}} \mathcal{P}_i) \equiv \text{true}
$$

---

### **6. Attestation Model**

An attestation $\mathcal{A}$ provides a non-repudiable cryptographic binding between an external identity (signer) and a specific ledger entry $\mathcal{E}$.

Let $\mathcal{A}$ be a tuple $\mathcal{A} = (\text{signer\_id}, \sigma)$, where $\sigma$ is a digital signature:
$$
\forall \mathcal{A}_k \in \mathcal{E}_{i+1}.\text{attestations} : \mathcal{V}_{\text{signer\_id}}, \text{Hash}(\mathcal{E}))
$$
The verification function $\mathcal{V}_{\text{attest}}$ is:
$$
\mathcal{V}_
