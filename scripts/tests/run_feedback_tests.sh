#!/usr/bin/env bash
set -euo pipefail
fail=0
run() { echo "[TEST] $1"; shift; if bash -e "$@"; then echo "  PASS"; else echo "  FAIL"; fail=$((fail+1)); fi; }

# 1) WASM panic handler present and buildable
cat > scripts/tests/feedback/01_wasm_panic_handler.sh << 'T1'
#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/src/lib.rs
# Check for a panic handler attribute
if ! rg -n "^#\[panic_handler\]" "$f" >/dev/null; then
  echo "panic handler missing in $f" >&2
  exit 1
fi
# Try to build (requires toolchain + target installed)
( cd tests/policy/wasm/demo && cargo build --release --target wasm32-unknown-unknown >/dev/null )
T1
chmod +x scripts/tests/feedback/01_wasm_panic_handler.sh

# 2) Release workflow tag guard and if-condition
cat > scripts/tests/feedback/02_release_tag_guard.sh << 'T2'
#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
# Check a tags line contains a strict semver-like pattern (literal)
rg -n "^\s*tags:\s*$" "$f" >/dev/null
grep -nF "- 'v[0-9]+.[0-9]+.[0-9]+'" "$f" >/dev/null
# Check we guard by ref_type/startsWith
rg -n "^\s*if:\s*github.ref_type == 'tag'.*startsWith\(github.ref, 'refs/tags/v'\)" "$f" >/dev/null
T2
chmod +x scripts/tests/feedback/02_release_tag_guard.sh

# 3) Release assets directory validation exists
cat > scripts/tests/feedback/03_release_dirs_validation.sh << 'T3'
#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
rg -n "for dir in schemas tests/vectors scripts/vectors; do" "$f" >/dev/null
rg -n "ERROR: Required directory '" "$f" >/dev/null
T3
chmod +x scripts/tests/feedback/03_release_dirs_validation.sh

# 4) Release workflow EOF no trailing blank line
cat > scripts/tests/feedback/04_release_eof.sh << 'T4'
#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
# Get last non-empty char
if [ ! -f "$f" ]; then echo "release.yml missing" >&2; exit 1; fi
last=$(tail -c 1 "$f" | od -An -t u1)
# 10 = newline; we want last char to NOT be newline
if [ "$last" = " 10" ]; then
  echo "Trailing newline at EOF in $f" >&2
  exit 1
fi
T4
chmod +x scripts/tests/feedback/04_release_eof.sh

# 5) Compliance links fixed (no ./SPEC.md or ./MODEL.md)
cat > scripts/tests/feedback/05_docs_compliance_links.sh << 'T5'
#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "\./SPEC\.md|\./MODEL\.md" "$f"; then
  echo "Found broken relative links in $f" >&2
  exit 1
fi
T5
chmod +x scripts/tests/feedback/05_docs_compliance_links.sh

# 6) Error taxonomy table has no hard tabs
cat > scripts/tests/feedback/06_docs_error_table_tabs.sh << 'T6'
#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "\t" "$f"; then
  echo "Found tabs in $f" >&2
  exit 1
fi
T6
chmod +x scripts/tests/feedback/06_docs_error_table_tabs.sh

# 7) Heading for Future Work is proper heading (no '12. Future Work' as list)
cat > scripts/tests/feedback/07_docs_heading_future.sh << 'T7'
#!/usr/bin/env bash
set -euo pipefail
f=docs/compliance/index.md
if rg -n "^12\. Future Work$" "$f"; then
  echo "Found list-style '12. Future Work' — should be '## 12. Future Work'" >&2
  exit 1
fi
T7
chmod +x scripts/tests/feedback/07_docs_heading_future.sh

# 8) Model source no bare code fences without language
cat > scripts/tests/feedback/08_model_source_codefence_lang.sh << 'T8'
#!/usr/bin/env bash
set -euo pipefail
f=docs/spec/model-source.md
# Fail if any bare code fence exists (exact line of ```)
if grep -xF '```' "$f"; then
  echo "Found bare code fence without language in $f" >&2
  exit 1
fi
T8
chmod +x scripts/tests/feedback/08_model_source_codefence_lang.sh

# 9) WASM Cargo.toml has size opts
cat > scripts/tests/feedback/09_wasm_cargo_optimizations.sh << 'T9'
#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/Cargo.toml
rg -n "^strip\s*=\s*true" "$f" >/dev/null
rg -n "^panic\s*=\s*\"abort\"" "$f" >/dev/null
T9
chmod +x scripts/tests/feedback/09_wasm_cargo_optimizations.sh

# 10) WASM Makefile no silent error suppression
cat > scripts/tests/feedback/10_wasm_makefile_errors.sh << 'T10'
#!/usr/bin/env bash
set -euo pipefail
f=tests/policy/wasm/demo/Makefile
if rg -n "\|\| true" "$f"; then
  echo "Makefile contains silent error suppression (|| true)" >&2
  exit 1
fi
# Ensure artifact check present
rg -n "\$\(OUT\)" "$f" >/dev/null
T10
chmod +x scripts/tests/feedback/10_wasm_makefile_errors.sh

# Run all
run 01 scripts/tests/feedback/01_wasm_panic_handler.sh || true
run 02 scripts/tests/feedback/02_release_tag_guard.sh || true
run 03 scripts/tests/feedback/03_release_dirs_validation.sh || true
run 04 scripts/tests/feedback/04_release_eof.sh || true
run 05 scripts/tests/feedback/05_docs_compliance_links.sh || true
run 06 scripts/tests/feedback/06_docs_error_table_tabs.sh || true
run 07 scripts/tests/feedback/07_docs_heading_future.sh || true
run 08 scripts/tests/feedback/08_model_source_codefence_lang.sh || true
run 09 scripts/tests/feedback/09_wasm_cargo_optimizations.sh || true
run 10 scripts/tests/feedback/10_wasm_makefile_errors.sh || true

if [ $fail -ne 0 ]; then
  echo "FAILED: $fail feedback checks failed" >&2
  exit 1
fi
