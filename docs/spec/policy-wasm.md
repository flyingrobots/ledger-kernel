---
title: Deterministic WASM Policy ABI
---

# Deterministic WASM Policy ABI (FS‑9)

This document specifies a minimal, deterministic host ABI for policy evaluation. It complements FS‑9 and the Compliance Policy/WASM level.

## 1. Goal

Provide a portable, deterministic interface for evaluating a policy over a candidate Entry and the previous state, returning a boolean decision and optional diagnostics.

## 2. Determinism Requirements

- Ambient time (wall‑clock/monotonic clocks) is forbidden.
- Randomness (RNG imports or entropy sources) is forbidden.
- I/O (filesystem, network, environment variables, process APIs) is forbidden.
- Resource limits: host MUST enforce fuel/step limits and a memory cap (e.g., 32–64 MiB) to prevent non‑termination.

## 3. Module Exports

The module SHALL export a single function:

```text
// Returns 1 (true) or 0 (false). Diagnostics are written to the out buffer.
// Pseudocode ABI; wire details (offsets/lengths) are host‑defined but MUST be
// documented and deterministic.
fn validate(entry_ptr: u32, entry_len: u32,
            state_ptr: u32, state_len: u32,
            out_ptr: u32, out_len_ptr: u32) -> u32
```

Inputs
- `entry` — canonical JSON bytes of the candidate Entry (see Wire Format).
- `state` — implementation‑defined, deterministic snapshot (JSON or empty for minimal hosts).

Outputs
- Return value — 1 = accepted, 0 = rejected.
- Diagnostics — UTF‑8 string (implementation‑defined), copied into `out` by the host after the call.

## 4. Allowed Imports

The module MUST NOT import any function other than the host allocator glue (e.g., `canonical_abi_realloc` for component model) and a bounded logging function if provided:

```text
// Optional, bounded logging (may be stubbed by host)
fn log(ptr: u32, len: u32)
```

If `log` is present, hosts MUST cap message size and rate; logs MUST NOT influence the decision outcome.

## 5. Example Policy

An example policy can be compiled from a tiny Rust/Go/AssemblyScript module that:
- Parses `entry` JSON,
- Checks required fields or enforces a simple rule (e.g., author id allow‑list),
- Returns 1/0 with a short diagnostic message.

## 6. Compliance

For the WASM level, the harness:
- invokes the same policy twice with identical inputs,
- expects identical return values and identical diagnostics.

Hosts MUST document memory/fuel limits and any optional imports. Any deviation MUST be reflected in FS‑9 profiles in future versions.
