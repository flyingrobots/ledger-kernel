---
title: Wire Format
---

# Wire Format

This page defines canonical encodings for Entries, Attestations, and related metadata. It operationalizes FS‑10 (Canonical Serialization & Hashing), FS‑1..FS‑3 (data structures), and FS‑12 (namespaces & storage).

Note on aliases: the filenames `schemas/entry.json`, `schemas/attest.json`, and `schemas/policy.json` are JSON Schema aliases that `$ref` the canonical definitions in `schemas/entry.schema.json`, `schemas/attestation.schema.json`, and `schemas/policy.schema.json` respectively.

## 1. Canonical Serialization (FS‑10)

Ledger‑Kernel uses a JSON representation with a strict canonicalization profile to ensure byte‑stable hashing and signing.

Rules
- UTF‑8 encoding; newline is LF (\n) only.
- Objects SHALL have unique member names and SHALL be serialized with members sorted by Unicode code point of the member name (ascending).
- No insignificant whitespace other than a single space after `:` and `,` is required; implementations MAY emit minimal whitespace, but canonicalization MUST produce a single, stable layout.
- Numbers in canonical fields MUST be integers. Non‑integer numeric data MUST be encoded as strings (e.g., quantities, decimals). Floating‑point values are forbidden in canonical fields.
- Strings MUST NOT contain unpaired surrogates; escaping MUST be minimal (e.g., `"`, `\\`, `\uXXXX` where necessary).

Canonicalization Function (pseudocode)
1) Validate JSON (no duplicate keys).
2) Sort object members recursively; arrays preserve order.
3) Enforce integer‑only numerics; reject floats in canonical positions.
4) Emit UTF‑8 with LF line endings.

The canonical byte sequence is the input to hashing and signing.

## 2. Hashing & Identifiers

Primary content hash: **BLAKE3‑256** over the canonical Entry preimage (see below). The digest SHALL be encoded as lowercase hex (64 hex chars).

Mirror hash (optional): **SHA‑256** over the same preimage, lowercase hex.

Preimage definition
- The Entry’s `id` is computed over the Entry object with the `attestations` field omitted (to avoid circularity). All other fields present MUST be included.

```
id = blake3_256_hex(canonical_json(entry_without_attestations))
sha256 = sha256_hex(canonical_json(entry_without_attestations))  # optional mirror
```

## 3. Entry JSON (FS‑1)

Required top‑level fields and types:

```json
{
  "id": "<hex blake3-256>",
  "parent": "<hex blake3-256>" ,
  "timestamp": "2025-01-01T00:00:00Z",
  "author": { "id": "<string>", "name": "<string>", "email": "<string>" },
  "payload": { "type": "text/json", "data": {} },
  "attestations": [ /* Attestation objects */ ]
}
```

Notes
- `parent` MAY be `null` for genesis.
- `author` keys beyond `id` are OPTIONAL.
- `payload.data` MAY be any JSON value; if it contains non‑integer numerics, they MUST be represented as strings.
- `id` MUST equal the BLAKE3‑256 of the canonical preimage as defined above.
- An optional `sha256` mirror MAY be carried in trailers (see §6).

A machine‑readable schema is provided in `schemas/entry.schema.json`.

## 4. Attestation JSON (FS‑2)

```json
{
  "signer": "did:key:z6Mkh..." ,
  "algorithm": "ed25519",
  "signature": "<base64url>",
  "scope": "append",
  "timestamp": "2025-01-01T00:00:00Z",
  "keyHint": "<optional fingerprint or key id>"
}
```

Signing Input
- To avoid ambiguity, an Attestation MUST sign the ASCII string:

```
"ledger-entry:" + id
```

where `id` is the Entry’s BLAKE3‑256 hex digest. Implementations MAY add additional domain separation (e.g., policy set hash) but MUST document it.

Schema: `schemas/attestation.schema.json`.

## 5. Policy Result (FS‑3)

```json
{
  "accepted": true,
  "reasons": ["policy:x.y accepted"]
}
```

Policy results are not hashed into the Entry `id`; they are artifacts of evaluation. If stored, they SHALL be placed in auxiliary refs as defined below. Schema: `schemas/policy_result.schema.json`.

## 6. Git Commit & Trailers (FS‑12)

Entries are committed as conventional Git commits under `refs/_ledger/<namespace>`.

Recommended trailers
```
LK-Id: <blake3-256 hex>
LK-Alg: blake3-256
LK-Parent: <blake3-256 hex or null>
LK-Payload-Type: <mime>
LK-Policy-OK: true|false
LK-Policy-Set: <opaque policy set id>  # optional
LK-SHA256: <sha256 hex>               # optional mirror
```

Implementations MAY include additional domain‑specific trailers. Trailer presence does not replace JSON canonicalization; hashes MUST be computed over the canonical preimage.

## 7. Example

```json
{
  "id": "b3d9…",
  "parent": "1ee6…",
  "timestamp": "2025-10-31T00:00:00Z",
  "author": { "id": "alice@example.org" },
  "payload": { "type": "text/json", "data": { "op": "append", "v": "1" } },
  "attestations": [
    {
      "signer": "did:key:z6Mk…",
      "algorithm": "ed25519",
      "signature": "MEYCIQ…",
      "scope": "append",
      "timestamp": "2025-10-31T00:00:01Z"
    }
  ]
}
```

Trailers
```
LK-Id: b3d9…
LK-Alg: blake3-256
LK-Parent: 1ee6…
LK-Payload-Type: text/json
LK-Policy-OK: true
LK-SHA256: 9a7c…
```

## 8. Schemas

- `schemas/entry.schema.json` — Entry object
- `schemas/attestation.schema.json` — Attestation object
- `schemas/policy_result.schema.json` — Policy evaluation result

These schemas are informative; the canonicalization and hashing rules above are normative.

### CBOR Canonical Profile (Optional)

Implementations MAY opt into a CBOR Canonical Encoding profile (RFC 8949 §4.2) for the id preimage. In this profile:

- The preimage is the canonical CBOR encoding of the Entry object with `attestations` omitted.
- The identifier `id_cbor` is defined as BLAKE3‑256 over the CBOR canonical bytes.
- JSON and CBOR preimages produce different byte sequences; ids therefore differ. Mixed mode MUST NOT be used within a single ledger without an explicit migration.

Dual‑format period
- Hosts MAY accept either JSON or CBOR preimages when verifying historical entries during a migration window. New entries SHOULD use one format exclusively per ledger namespace.
- Implementations MUST document which profile is active and SHOULD record a trailer (e.g., `LK-Profile: json1|cbor1`).
