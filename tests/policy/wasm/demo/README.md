# Deterministic WASM Policy Demo

This minimal Rust crate builds a `wasm32-unknown-unknown` module exporting a single function:

```
// extern "C" ABI
u32 validate(entry_ptr, entry_len, state_ptr, state_len, out_ptr, out_len_ptr)
```

- Returns `0` on acceptance; non-zero on rejection.
- Writes a short message (`ACCEPT` or `REJECT`) into the caller-provided buffer if non-null.
- Deterministic: no clock, RNG, network, filesystem, or host I/O.

Acceptance rule (demo): accept iff both `entry_len` and `state_len` are even.

## Build

- Install the target once:

```
rustup target add wasm32-unknown-unknown
```

- Build release artifact:

```
cargo build --release --target wasm32-unknown-unknown
```

- The resulting module will be at:

```
./target/wasm32-unknown-unknown/release/policy_wasm_demo.wasm
```

## Host ABI Notes

A real host would:
- pass pointers to the canonical entry bytes and current state bytes;
- provide an output buffer and read the length written at `out_len_ptr`;
- sandbox execution (fuel/step limits, memory limits) and enforce determinism.

This crate is for conformance demos only.

