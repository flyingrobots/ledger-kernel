---
Author: J. Kirby Ross <james@flyingrobots.dev> (https://github.com/flyingrobots) 
Created: 2025-10-27
License: MIT
Scope: This document describes the *language-neutral Application Programming Interface (API) contract* for the Ledger-Kernel.
Status: Draft
Summary: Defines the invariants, operations, and compliance requirements for a Git-native append-only ledger.
Version: 0.1.0 
---

# **Ledger-Kernel Reference Application Programming Interface Specification**

## 1.0 Overview

This document describes the *language-neutral Application Programming Interface (API) contract* for the Ledger-Kernel. It provides the baseline set of functions, abstract data structures, and return value semantics that all compliant implementations must support.

The primary objective of this specification is to guarantee **interoperability**. A faithful implementation of this interface ensures that any two libraries, regardless of their internal implementation language or details, can operate on the same Git repository and ledger structure without requiring any intermediate translation or data transformation.

---

## 2.0 API Design Principles and Conventions

The API contract is designed around a set of C-style conventions to ensure maximum portability and deterministic behavior.

**Status Codes:** All functions must return an integer status code of type `ledger_status_t`. A value of zero (`LEDGER_OK`) universally signifies success, while any non-zero value indicates a specific error condition.

**Opaque Handles:** All primary resources (e.g., `ledger_ctx_t`, `ledger_entry_t`) are managed as opaque handles (pointers to incomplete types). Their internal structure is implementation-defined and must not be accessed directly.

**Resource Management:** Opaque handles must be explicitly released by the caller using their corresponding `_free()` function (e.g., `ledger_free()`) to prevent resource leaks.

**Data Structures:** All non-opaque structs (e.g., `ledger_result_t`) are defined as *plain-old data* (POD) types with deterministic binary layouts to ensure consistent memory representation across different C compilers and language bindings.

**String Encoding:** All character strings passed to or returned from the API must be UTF-8 encoded and terminated by a `null` character.

---

## 3.0 Core Data Structures and Enumerations

Implementations must provide types that are behaviorally and semantically equivalent to the following C `typedef`s and `enum`. These definitions form the abstract type system of the API.

```c
/* Opaque handle to the repository context */
typedef struct ledger_ctx ledger_ctx_t;

/* Opaque handle to a single ledger entry */
typedef struct ledger_entry ledger_entry_t;

/* Opaque handle to a replayed ledger state */
typedef struct ledger_state ledger_state_t;

/* Opaque handle to a loaded policy */
typedef struct ledger_policy ledger_policy_t;

/* Opaque handle to an attestation */
typedef struct ledger_attest ledger_attest_t;

/* A plain-data struct for verification results */
typedef struct ledger_result ledger_result_t;

/* Standardized operational status codes */
typedef enum {
  /* Operation completed successfully */
  LEDGER_OK = 0,
  /* Append failed invariants (e.g., non-fast forward) */
  LEDGER_ERR_APPEND_REJECTED,
  /* An attestation signature was invalid */
  LEDGER_ERR_SIG_INVALID,
  /* A policy function returned 'false' */
  LEDGER_ERR_POLICY_FAIL,
  /* Deterministic replay produced a different state */
  LEDGER_ERR_REPLAY_MISMATCH,
  /* Entry timestamp was not >= parent timestamp */
  LEDGER_ERR_TEMPORAL_ORDER,
  /* Invalid ref path or namespace violation */
  LEDGER_ERR_NAMESPACE,
  /* Underlying storage or I/O error */
  LEDGER_ERR_IO,
  /* A generic, unspecified error */
  LEDGER_ERR_UNKNOWN
} ledger_status_t;
```

---

## 4.0 Context Lifecycle Management

These functions manage the primary repository context.

```c
/**
* Initializes a ledger context for an existing Git repository.
*
* @param ctx An out-parameter to store the pointer to the new context.
* @param repo_path A path to the root of the Git repository.
* @return LEDGER_OK on success, or an error code.
*/
int ledger_init(ledger_ctx_t **ctx, const char *repo_path);

/**
* Closes the ledger context and frees all associated memory.
*
* @param ctx The context to free.
*/
void ledger_free(ledger_ctx_t *ctx);
```

---

## 5.0 Ledger Entry Operations

These functions are used to create, process, and append ledger entries.

```c
/**
* Creates a new, in-memory ledger entry from a raw payload buffer.
*
* @param out An out-parameter to store the pointer to the new entry.
* @param type A MIME-type string for the payload (e.g., "text/json").
* @param data A pointer to the raw payload data.
* @param len The length of the data buffer in bytes.
* @return LEDGER_OK on success.
*/
int ledger_entry_new(ledger_entry_t **out, const char *type, const void *data, size_t len);

/**
* Serializes a ledger entry into its canonical JSON representation.
*
* @param entry The entry to serialize.
* @param out_json An out-parameter to store the pointer to the new string.
* The caller is responsible for freeing this string.
* @return LEDGER_OK on success.
*/
int ledger_entry_serialize(const ledger_entry_t *entry, char **out_json);

/**
* Computes the deterministic cryptographic hash of the entry.
*
* @param entry The entry to hash.
* @param out_hash A 32-byte buffer to store the resulting hash.
* @return LEDGER_OK on success.
*/
int ledger_entry_hash(const ledger_entry_t *entry, unsigned char out_hash[32]);

/**
* Appends a validated entry to the ledger under a specific ref path.
* This operation must atomically enforce all kernel invariants.
*
* @param ctx The repository context.
* @param ref The full ledger ref path (e.g., "refs/_ledger/main").
* @param entry The entry to append.
* @return LEDGER_OK on success, or an error code (e.g.,
* LEDGER_ERR_APPEND_REJECTED, LEDGER_ERR_POLICY_FAIL).
*/
int ledger_append(ledger_ctx_t *ctx, const char *ref, const ledger_entry_t *entry);

/**
* Frees all memory associated with a ledger entry.
*
* @param entry The entry to free.
*/
void ledger_entry_free(ledger_entry_t *entry);
```

---

## 6.0 Attestation Management and Cryptography

These functions manage the creation and verification of cryptographic attestations.

```c
/**
* Creates a new attestation by signing an entry's hash.
*
* @param ctx The repository context (for key management).
* @param entry The entry to sign.
* @param signer_id An identifier for the signer (e.g., GPG fingerprint).
* @param key_path A path or identifier for the private key.
* @param out_attest An out-parameter to store the new attestation.
* @return LEDGER_OK on success, or an error code.
*/
int ledger_attest_sign(ledger_ctx_t *ctx, const ledger_entry_t *entry,
const char *signer_id, const char *key_path,
ledger_attest_t **out_attest);

/**
* Verifies the signature of an attestation against its entry.
*
* @param entry The entry the attestation claims to sign.
* @param attest The attestation to verify.
* @return LEDGER_OK if the signature is valid, or LEDGER_ERR_SIG_INVALID.
*/
int ledger_attest_verify(const ledger_entry_t *entry, const ledger_attest_t *attest);

/**
* Attaches a valid attestation to an in-memory entry (prior to append).
*
* @param entry The entry to modify.
* @param attest The attestation to add.
* @return LEDGER_OK on success.
*/

int ledger_entry_add_attest(ledger_entry_t *entry, const ledger_attest_t *attest);

/**
* Frees all memory associated with an attestation.
*
* @param attest The attestation to free.
*/
void ledger_attest_free(ledger_attest_t *attest);
```

---

## 7.0 Policy Evaluation Interface

These functions manage the loading and execution of deterministic policies.

```c
/**
* Loads and prepares a policy from a file or serialized data.
*
* @param ctx The repository context.
* @param path A path to the policy file (e.g., a WASM binary or script).
* @param out An out-parameter to store the loaded policy.
* @return LEDGER_OK on success.
*/
int ledger_policy_load(ledger_ctx_t *ctx, const char *path, ledger_policy_t **out);

/**
* Evaluates a policy against a candidate entry in a given context.
* This function must be pure and deterministic.
*
* @param ctx The repository context.
* @param policy The policy to execute.
* @param entry The candidate entry to evaluate.
* @param out_pass An out-parameter to store the result (1 for pass, 0 for fail).
* @return LEDGER_OK on success, or an error code if evaluation failed.
*/
int ledger_policy_eval(const ledger_ctx_t *ctx, const ledger_policy_t *policy,
const ledger_entry_t *entry, int *out_pass);

/**
* Frees all memory associated with a loaded policy.
*
* @param policy The policy to free.
*/
void ledger_policy_free(ledger_policy_t *policy);
```

---

## 8.0 State Reconstruction and Verification

These functions provide the core replay and verification capabilities.

```c
/**
* Deterministically reconstructs the ledger's derived state. This operation iterates over all entries from the genesis entry to the head of the specified ref.
*
* @param ctx The repository context.
* @param ref The full ledger ref path to replay.
* @param out_state An out-parameter to store the final replayed state.
* @return LEDGER_OK on success, or LEDGER_ERR_REPLAY_MISMATCH if
* a local invariant fails.
*/
int ledger_replay(ledger_ctx_t *ctx, const char *ref, ledger_state_t **out_state);

/**
* Computes a deterministic cryptographic digest of the replayed state.
*
* @param state The state object returned by ledger_replay.
* @param out_hash A 32-byte buffer to store the resulting hash.
* @return LEDGER_OK on success.
*/
int ledger_state_digest(const ledger_state_t *state, unsigned char out_hash[32]);

/**
* Verifies the full integrity of a ledger.
* This checks all invariants: entry hashes, attestations, and policies.
*
* @param ctx The repository context.
* @param ref The full ledger ref path to verify.
* @param out_result An out-parameter to store the verification result object.
* @return LEDGER_OK if verification was successful (result->status == LEDGER_OK),
* or an error code if the verification process itself failed.
*/
int ledger_verify(ledger_ctx_t *ctx, const char *ref, ledger_result_t **out_result);

/**
* Frees all memory associated with a replayed state object.
*
* @param state The state object to free.
*/
void ledger_state_free(ledger_state_t *state);

/**
* Frees all memory associated with a verification result object.
*
* @param result The result object to free.
*/
void ledger_result_free(ledger_result_t *result);
```

---

## 9.0 Result Object Specification

The `ledger_result_t` structure is a non-opaque POD type used to return data from verification operations.

```c
typedef struct {
  /* The final status of the operation */
  ledger_status_t status;
  
  /* A human-readable, deterministic message */
  char *message;
  
  /* The ref that was processed */
  char *ref;

  /* The final digest of the state */
  unsigned char digest[32];
} ledger_result_t;
```

Implementations must ensure that the `status` field uses one of the standard `ledger_status_t` codes from Section 3. The `message` string should be human-readable but must be generated deterministically across all platforms for a given state.

---

## 10.0 Standardized Error Handling

All compliant implementations must expose a global, pure function for formatting error codes.

```c
/**
* Returns a constant, null-terminated string describing an error code.
*
* @param code The status code to format.
* @return A read-only, human-readable error string.
*/
const char *ledger_strerror(ledger_status_t code);
```

All functions defined in this specification must be pure with respect to their inputs and must not produce undefined behavior, even in error conditions.

---

## 11.0 Non-Normative Environment Variables

Implementations may, at their discretion, inspect environment variables to modify non-normative behavior, such as logging. These variables must not influence the deterministic outcome of any core operation.

| Variable | Meaning |
|---|---|
| `LEDGER_DEBUG=1` | Enables verbose, implementation-defined logging. |
| `LEDGER_POLICY_PATH` | Provides a default path for loading policy files. |
| `LEDGER_SIGNER` | Provides a default signer fingerprint or ID. |

These are considered implementation-specific hints and are not part of the formal API contract. Implementations **MAY** ignore these.

---

## 12.0 Foreign Function Interface (FFI) and Language Bindings

This API is defined in terms of a C header (`ledger.h`) to serve as a stable, canonical interface. Bindings for other languages must mirror this API's semantics precisely.

| Language | File | Notes |
|---|---|---|
| C | `ledger.h` | The canonical header file. |
| Rust | `ledger.rs` | A thin FFI wrapper over the C API. |
| Go | `ledger.go` | A cgo wrapper. |
| JS/WASM | `ledger.js` | An ESM module compiled from the C implementation. |

It is a critical requirement that all language bindings must not introduce hidden randomness or non-deterministic serialization logic. They must preserve the deterministic guarantees of the canonical C interface.

---

## 13.0 Compliance Proof Generation

Each function that mutates a ledger (e.g., `ledger_append`) must emit a machine-readable compliance proof artifact to the following path within the Git repository's private directory:

```bash
.git/_ledger/_proofs/<operation>_<timestamp>.json
```

The precise format and content of this proof are defined in the accompanying `COMPLIANCE.md` specification.

---

## 14.0 API Version Negotiation

Implementations must expose a function to query the specification version they conform to.

```c
/**
* Returns a constant string identifying the specification version.
*
* @return A read-only string (e.g., "ledger-kernel/0.1.0").
*/
const char *ledger_version(void);
```

This allows consuming applications to negotiate or verify the implementation's capabilities at runtime.

---

## 15.0 Illustrative Example (Non-Normative)

The following C code snippet provides a minimal, non-normative example of the API's intended use for initializing a context, creating an entry, and appending it to a ledger.

```c
ledger_ctx_t *ctx;
ledger_entry_t *e;
ledger_status_t status;

status = ledger_init(&ctx, ".");

if (status != LEDGER_OK) { /* handle error */ }

status = ledger_entry_new(&e, "text/json", "{\"msg\":\"hello\"}", 18);

if (status != LEDGER_OK) { /* handle error */ }

status = ledger_append(ctx, "refs/_ledger/demo", e);

if (status != LEDGER_OK) { /* handle error */ }

/* Clean up resources */
ledger_entry_free(e);
ledger_free(ctx);
```

---

## 16.0 Concluding Remarks

The Reference API specified herein is intentionally low-level, providing the core primitives for ledger manipulation and verification.

Higher-level client libraries may be constructed to wrap these calls, providing a more ergonomic interface. However, any such library must remain fully deterministic and verifiable, inheriting and preserving the invariants enforced by this canonical API.

Any modification to the function signatures, data structures, or semantic behavior defined in this document requires an increment of the major version number of the Ledger-Kernel specification.
