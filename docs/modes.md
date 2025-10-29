# Modes

This project supports multiple storage modes with clear defaults.

- Proofs: branch (default), notes, private workdir
- Attestations: attestation branch (default), commit signature, notes
- Hashing: BLAKE3 primary + SHA-256 mirror
- Policy: hostless WASM (no WASI), deterministic
- Timestamps: ISO-8601 UTC, monotonic vs parent
- Canonical JSON: sorted keys, UTF-8, no floats in canonical fields

