## 🐞 WASM Demo Missing Panic Handler

The new WASM policy demo is compiled as a cdylib with #![no_std] but does not define a #[panic_handler] (nor depend on a crate that supplies one). no_std crates require a panic handler; without it, cargo build --target wasm32-unknown-unknown fails with lang item required, but not found: panic_impl, so the example cannot be built as advertised.

```
// No code suggestion provided by bot. Must be implemented in Rust.
```

NOTES:
- Target: `tests/policy/wasm/demo/src/lib.rs`. Must implement a basic `#[panic_handler]` function.

### Status

- [x] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

Evidence:
- Added `#[panic_handler]` in `tests/policy/wasm/demo/src/lib.rs` and verified build: `cargo build --release --target wasm32-unknown-unknown` succeeds locally.

---

## 🛡️ Release Workflow Needs Stricter Tag and Branch Guards

Tag-triggered release workflows need safeguards to prevent accidental/invalid releases. The workflow triggers on any tag matching `v*`.

```yaml
# Suggested change structure for .github/workflows/release.yml:
on:
push:
  tags:
    - 'v[0-9]+.[0-9]+.[0-9]+*'
jobs:
release:
  runs-on: ubuntu-latest
  if: github.ref_type == 'tag' && startsWith(github.ref, 'refs/tags/v')
# OR use draft release:
# with:
#   draft: true
```

NOTES:

- Target: `.github/workflows/release.yml`. Options include tightening the tag regex, adding a branch guard (`if: ...`), or setting `draft: true` on the release action.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📦 Release Assets Missing Directory Validation

Missing validation: directories must exist before zipping, or the workflow will fail with unclear errors. The `zip -r` commands assume `schemas/`, `tests/vectors/`, and `scripts/vectors/` exist.

```bash
# Suggested change structure for .github/workflows/release.yml:
for dir in schemas tests/vectors scripts/vectors; do
if [ ! -d "$dir" ]; then
  echo "ERROR: Required directory '$dir' not found"
  exit 1
fi
done
zip -r dist/schemas.zip schemas
zip -r dist/vectors.zip tests/vectors scripts/vectors
```

NOTES:
- Target: `.github/workflows/release.yml` in the `Prepare assets` step. Implement defensive checks or document the assumption.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🧹 Release Workflow Trailing Blank Line

Remove trailing blank line. YAMLlint correctly flags an unnecessary blank line at the end of the file (line 34).

```
// Remove blank line at EOF in .github/workflows/release.yml
```

NOTES:
- Target: `.github/workflows/release.yml`. Trivial cleanup to satisfy YAMLlint.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---


## 🔗 Compliance Docs Broken Links

Fix broken documentation links: use correct relative paths to SPEC.md and MODEL.md. The links `./SPEC.md` and `./MODEL.md` point to files in the repo root but resolve incorrectly from `docs/compliance/`.

```
// Suggested change structure for docs/compliance/index.md:
adheres to the invariants, semantics, and deterministic behavior defined in [suspicious link removed] and [suspicious link removed].
```

NOTES:
- Target: `docs/compliance/index.md`. Update paths to use `../../SPEC.md` and `../../MODEL.md`.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📝 Error Taxonomy Table Malformed (Tabs/Delimiters)

🔴 Critical: Error taxonomy table is malformed—missing cell delimiters and hard tabs corrupt structure. Markdown table parsers expect pipe-delimited columns with spaces, not tabs.

```
// Requires manually reconstructing the table rows (lines 128-133) with pipe delimiters ('|') and replacing hard tabs with spaces.
```

NOTES:
- Target: `docs/compliance/index.md`. Critical formatting fix for the error taxonomy table structure.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📐 Compliance Docs - Heading Numbering/Style Fix

Minor: Fix ordered list heading numbering (MD029). Line 204 reads `12. Future Work` (with period), which triggers MD029 violation (expects consistent 1. prefix for ordered lists). Change this line to be a proper heading.

```markdown
## 12. Future Work
```

NOTES:

- Target: `docs/compliance/index.md`. Trivial fix to promote the list item to a proper section heading.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🎨 Model Spec Missing Code Block Language Specifiers

Minor: Add language specifiers to all fenced code blocks (MD040). Fenced blocks at lines 5, 20, 26, 32 lack language identifiers (e.g., ```math or ```latex).

````
// Suggested change structure for docs/spec/model-source.md:
```math
````

NOTES:
- Target: `docs/spec/model-source.md`. Repeat for all four blocks.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## ⚡ WASM Demo Cargo.toml Size Optimizations

Consider additional size optimizations for production use. For further reduction, consider adding `strip = true` and `panic = "abort"` to the `[profile.release]` section.

```toml
[profile.release]
opt-level = "s"
codegen-units = 1
debug = false
lto = true
strip = true
panic = "abort"
```

NOTES:

- Target: `tests/policy/wasm/demo/Cargo.toml`. Recommended optimization for WASM binary size.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## ⚠️ WASM Demo Makefile Silent Error Suppression

The silent error suppression is unacceptable for a build system. Line 10 uses `|| true` to suppress all errors from `rustup target add`, which will hide legitimate failures.

```bash
# Suggested approach: Propagate errors and verify output artifact.
# 1. Ensure rustup is available.
# 2. Run rustup target add $(TARGET) without swallowing errors.
# 3. Verify the expected .wasm output artifact exists.
```

NOTES:
- Target: `tests/policy/wasm/demo/Makefile`. Remove `|| true` and add explicit failure handling.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📝 WASM Demo README Code Block Specifiers

Fix markdown code block language specifiers for proper syntax highlighting. Four code blocks are missing language specifiers.

````
// Suggested change structure for tests/policy/wasm/demo/README.md:
// First block:
c
// Command blocks:
```bash
// Final path block:
```text
````

NOTES:

- Target: `tests/policy/wasm/demo/README.md`. Use `c`, `bash`, and `text` for the respective blocks.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🚨 WASM FFI Missing Safety Preconditions

Documentation lacks critical safety preconditions for the FFI contract. The caller contract for the `validate` function's unsafe pointer operations must be explicitly documented in the code itself.

```rust
// Suggested documentation to add to tests/policy/wasm/demo/src/lib.rs:
// # Safety Requirements (Caller Contract):
//  - entry_ptr must be valid for reads of entry_len bytes (or null if entry_len is 0)
//  - state_ptr must be valid for reads of state_len bytes (or null if state_len is 0)
//  - If out_ptr is non-null, it must be valid for writes of *out_len_ptr bytes
//  - If out_len_ptr is non-null, it must be valid for reads and writes of usize
//  - All non-null pointers must be properly aligned for their respective types
//  - The output buffer [out_ptr, out_ptr + *out_len_ptr) must not overlap with inputs
```

NOTES:
- Target: `tests/policy/wasm/demo/src/lib.rs`. Add a concise Safety documentation block to the function comment.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🧹 CI Workflow YAML Formatting

Fix YAML formatting for consistency. Static analysis flags several style issues: bracket/brace spacing, improper truthy values, and extra blank lines.

```yaml
# Suggested change structure for .github/workflows/vectors-cbor.yml and vectors-matrix.yml:
# Normalize list style:
branches: [main]
# Normalize brace spacing:
with: {go-version: '1.21.x'} -> with: { go-version: '1.21.x' }
```

NOTES:

- Targets: `.github/workflows/vectors-cbor.yml` and `.github/workflows/vectors-matrix.yml`. Trivial cleanup to satisfy static analysis.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 💥 CI C Verification Compilation Logic Flaw

Critical: C verification compilation is incorrect. Line 65 attempts to compile from stdin (`-x c -`) while also providing `blake3_id.c` as an argument, but stdin is empty at that point. The compilation logic is flawed.

```bash
# Suggested fix for .github/workflows/vectors-matrix.yml:
# Compile the C tool
gcc -O2 -lblake3 -o c_b3sum scripts/vectors/c/blake3_id.c
# Generate canonical bytes and pipe to C tool
python scripts/vectors/python/canon.py tests/vectors/core/entry_canonical.json | ./c_b3sum > c_id.txt
```

NOTES:
- Target: `.github/workflows/vectors-matrix.yml` (C check step). Must compile the source file explicitly before piping input to the resulting binary.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🔗 Implementers Docs Broken Schema Link

Broken schema link. `./schemas/compliance_report.schema.json` resolves incorrectly to `/implementation/schemas/...`. The schema lives at the repo root.

```text
// Suggested change structure for docs/implementation/implementers.md:
The report **MUST** validate against the [schema](https://www.google.com/search?q=/schemas/compliance_report.schema.json).
```

NOTES:
- Target: `docs/implementation/implementers.md`. Update the link to be repository root-relative.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🗣️ WASM Spec Repetitive Constraint Phrasing

Three successive bullets starting with "No" create a repetitive pattern. Reword them for variety while preserving the constraints.

```markdown
- Ambient time (wall‑clock/monotonic clocks) is forbidden.
- Randomness (RNG imports or entropy sources) is forbidden.
- I/O (filesystem, network, environment variables, process APIs) is forbidden.
- Resource limits: host MUST enforce fuel/step limits and a memory cap (e.g., 32–64 MiB) to prevent non‑termination.
```

NOTES:
- Target: `docs/spec/policy-wasm.md`. Trivial nitpick for writing style.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📐 Wire Format Docs Missing Heading Blank Line

Fix markdown formatting: missing blank line before heading. Headings must be surrounded by blank lines for proper rendering and consistency.

```
// Add a blank line immediately before the heading "### CBOR Canonical Profile (Optional)" in docs/spec/wire-format.md
```

NOTES:
- Target: `docs/spec/wire-format.md`. Trivial fix (MD022 violation).

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## ⏱️ Sample Config Missing Per-Check Timeout Demo

Consider demonstrating per-check timeout in sample config. The sample config shows only the global `timeout_sec = 20` but doesn't demonstrate per-check timeout overrides.

```toml
[checks.C-4]
clause = ["FS-3","FS-9"]
level = "policy"
timeout_sec = 10 # <-- Add this line
cmd = "bash -c 'exit 64'"  # simulate PARTIAL
```

NOTES:

- Target: `scripts/harness/config.sample.toml`. Add `timeout_sec` to a check (e.g., `checks.C-4`) to show override semantics.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 📜 Harness README Missing Blank Lines Around Code Blocks

Add blank lines around fenced code blocks. Markdown best practices require blank lines before and after fenced code blocks for consistent rendering.

```
// Add blank lines before and after the fenced code blocks in scripts/harness/README.md
```

NOTES:
- Target: `scripts/harness/README.md`. Trivial fix.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## ⚠️ Harness Run Script Undeterministic Iteration Order

You promised config order, you delivered hash chaos. `"${!check_cmd[@]}"` iterates an associative array in arbitrary order. The shell will shuffle them on every run.

```bash
# Refactor the loop to iterate an indexed array (check_order) populated when parsing the config.
```

NOTES:

- Target: `scripts/harness/run.sh`. Must modify the parsing logic (outside the provided snippet) to capture order, and update the loop to use that ordered array.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}

---

## 🐛 Harness Run Script Defaulting Clauses to Bogus Value

Defaulting clauses to `"-"` is nonsense. When a check omits clause, this block feeds `"-"` into `append_result`, causing every clause-less entry to report a fake clause.

```bash
# Suggested change structure for scripts/harness/run.sh:
clauses="${check_clause[$key]:-""}" # Change default from "-" to ""
```

NOTES:
- Target: `scripts/harness/run.sh`. Change the default parameter value for `clauses`.

### Status

- [ ] Resolved
- [ ] Was Already Fixed
- [ ] Ignored

{evidence and/or rationale}
