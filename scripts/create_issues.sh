#!/usr/bin/env bash
set -euo pipefail

# This script creates labels, milestones, epics, and tasks for the 1.0.0 backlog.
# Requires: GitHub CLI (`gh`) authenticated to the current repo.

info() { printf "[info] %s\n" "$*"; }
warn() { printf "[warn] %s\n" "$*"; }

ensure_label() {
  local name=$1 color=$2
  if gh label list --limit 200 --json name --jq '.[].name' | rg -n "^${name}$" >/dev/null 2>&1; then
    info "label exists: ${name}"
  else
    gh label create "$name" --color "$color" --description "$name" || warn "label create failed or exists: $name"
  fi
}

ensure_milestone() {
  local title=$1 desc=${2:-""}
  local repo
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
  # list milestones via REST
  if gh api -H "Accept: application/vnd.github+json" \
      "repos/${repo}/milestones?state=all" --jq '.[].title' | rg -n "^${title}$" >/dev/null 2>&1; then
    info "milestone exists: ${title}"
  else
    gh api -H "Accept: application/vnd.github+json" -X POST \
      "repos/${repo}/milestones" \
      -f title="$title" -f description="$desc" >/dev/null \
      || warn "milestone create failed or exists: $title"
  fi
}

create_issue() {
  local title=$1 body=$2 labels=$3 milestone=$4
  local tmp
  tmp=$(mktemp)
  printf "%s\n" "$body" > "$tmp"
  local out num
  out=$(gh issue create --title "$title" --body-file "$tmp" ${labels:+--label $labels} ${milestone:+--milestone "$milestone"} 2>&1 || true)
  rm -f "$tmp"
  # Try to extract the created issue number from the URL or output
  num=$(printf "%s\n" "$out" | rg -o 'issues/\d+' | rg -o '\d+' | tail -n1)
  if [[ -z "$num" ]]; then
    warn "could not parse issue number for: $title"
    printf ""
  else
    printf "%s" "$num"
  fi
}

# 1) Labels
info "Ensuring labels..."
ensure_label epic 5319e7
ensure_label spec 0e8a16
ensure_label docs 0366d6
ensure_label schema 1f883d
ensure_label examples 0ea5e9
ensure_label compliance d93f0b
ensure_label ci fbca04
ensure_label site 0052cc
ensure_label governance c2e0c6
ensure_label security b60205
ensure_label templates 6f42c1
ensure_label hygiene c5def5
ensure_label decision 8f7ee6
ensure_label blocked d73a4a
ensure_label "good-first-issue" a2eeef
ensure_label "help-wanted" 7057ff

# 2) Milestones
info "Ensuring milestones..."
ensure_milestone "M0 Repo Hygiene" "Clean filenames/links/tables"
ensure_milestone "M1 Norms" "Decisions + config + compaction"
ensure_milestone "M2 Spec Freeze RC" "Harmonize core docs"
ensure_milestone "M3 Schemas+Examples" "Schemas + runnable examples"
ensure_milestone "M4 Compliance MVP" "8 core invariants + harness"
ensure_milestone "M5 Docs+CI" "VitePress site + checks"
ensure_milestone "M6 Governance+Security" "Policies, changelog, security"
ensure_milestone "v1.0.0" "Release milestone"

# 3) Epics
info "Creating epics..."
declare -A EPICS

EPICS[F2]=$(create_issue \
  "Epic: Norms & Conventions (proofs, attestations, hashing, policy, time, JSON)" \
  "Context: Define defaults while supporting all three modes for proofs and attestations; adopt BLAKE3+SHA256, deterministic WASM, UTC timestamps, canonical JSON; include compaction.\n\nAcceptance:\n- SPEC/ARCHITECTURE: 'Modes and Defaults' section\n- REFERENCE: config keys + defaults\n- COMPLIANCE: how tests declare selected modes\n- Diagrams/text aligned across docs\n\nDependencies: M0 Repo Hygiene" \
  "epic,spec,decision" \
  "M1 Norms")

EPICS[F1]=$(create_issue \
  "Epic: Spec Freeze 1.0.0" \
  "Freeze SPEC/MODEL/REFERENCE/ARCHITECTURE/COMPLIANCE; remove non-rendering admonitions; harmonize terms and IDs/digests with F2." \
  "epic,spec" \
  "M2 Spec Freeze RC")

EPICS[F4]=$(create_issue \
  "Epic: JSON Schemas" \
  "Machine-checkable schemas for entries, attestations, proofs (incl. snapshots), and policies; validation script." \
  "epic,schema" \
  "M3 Schemas+Examples")

EPICS[F5]=$(create_issue \
  "Epic: Examples Pack" \
  "Runnable examples covering each supported mode (proofs branch/notes/private, attestation branch/notes/commit), replay walkthrough." \
  "epic,examples" \
  "M3 Schemas+Examples")

EPICS[F3]=$(create_issue \
  "Epic: Compliance Suite v1" \
  "Harness and fixtures for 8 core invariants; mode-aware verifier; Core quorum ≥1, Extended includes 2-of-3." \
  "epic,compliance" \
  "M4 Compliance MVP")

EPICS[F6]=$(create_issue \
  "Epic: Docs Site (VitePress) & Publishing" \
  "VitePress site, decisions/modes pages, GitHub Pages workflow, README cleanup." \
  "epic,site,docs" \
  "M5 Docs+CI")

EPICS[F7]=$(create_issue \
  "Epic: CI & Validation" \
  "Markdown lint, link-check, schema validation, VitePress build, Mermaid/render strategy." \
  "epic,ci" \
  "M5 Docs+CI")

EPICS[F8]=$(create_issue \
  "Epic: Governance & Versioning" \
  "CHANGELOG, version negotiation, release checklist, spec freeze process." \
  "epic,governance" \
  "M6 Governance+Security")

EPICS[F9]=$(create_issue \
  "Epic: Security & Threat Model" \
  "SECURITY.md, threat model (tamper/replay/time skew/policy bypass), key guidance." \
  "epic,security" \
  "M6 Governance+Security")

EPICS[F11]=$(create_issue \
  "Epic: Assets & Repo Hygiene" \
  "Fix filenames/links/tables; logo path; directory typos; test filename scheme." \
  "epic,hygiene,docs" \
  "M0 Repo Hygiene")

EPICS[F10]=$(create_issue \
  "Epic: Community & Templates" \
  "CONTRIBUTING, CODE_OF_CONDUCT, issue/PR templates, labels guide." \
  "epic,governance,templates" \
  "M6 Governance+Security")

info "Epics created: ${EPICS[*]}"

# Helper to add a child issue with Parent line
child_issue() {
  local title=$1 body=$2 labels=$3 milestone=$4 parent_key=$5
  local parent_num=${EPICS[$parent_key]:-}
  if [[ -z "$parent_num" ]]; then
    warn "Unknown parent key: $parent_key"
    parent_num=""
  else
    body+=$'\n\nParent: #'"$parent_num"
  fi
  create_issue "$title" "$body" "$labels" "$milestone"
}

info "Creating tasks..."

# F11 Hygiene tasks
child_issue "Rename NOTICE.m → NOTICE.md" \
  "Rename file and fix any references. Acceptance: NOTICE.md present; links resolve." \
  "hygiene,docs" "M0 Repo Hygiene" F11 >/dev/null

child_issue "Fix README tables and stray hyphens" \
  "Correct Core Invariants and Documentation tables; remove stray '-' artifacts." \
  "hygiene,docs" "M0 Repo Hygiene" F11 >/dev/null

child_issue "Fix typo: tests/fixtures/miniaml_repo → minimal_repo" \
  "Rename directory and update any references." \
  "hygiene,docs" "M0 Repo Hygiene" F11 >/dev/null

child_issue "Align test filenames or COMPLIANCE to naming" \
  "Choose either 0N_*.yaml or *.test.yaml; update COMPLIANCE accordingly." \
  "hygiene,compliance" "M0 Repo Hygiene" F11 >/dev/null

child_issue "Logo asset path: add image or remove from README" \
  "Resolve broken image: add docs/images/ledger-kernel-logo.png or remove reference." \
  "hygiene,docs" "M0 Repo Hygiene" F11 >/dev/null

# F2 Norms
child_issue "Spec: Proofs storage modes + defaults + paths" \
  $'Add SPEC section defining branch (default), notes, and private proofs storage. Include filename conventions and retention/redaction guidance.' \
  "spec,decision" "M1 Norms" F2 >/dev/null

child_issue "Spec: Attestation storage modes + resolver" \
  $'Define commit sig, notes, and attestation branch (default). Document attestation resolver by entry-id across modes.' \
  "spec,decision" "M1 Norms" F2 >/dev/null

child_issue "Config: _meta/config.json keys for modes" \
  $'Add config keys (proofs.mode, attest.mode, hashing, policy.wasm, timestamps.source). Update REFERENCE & ARCHITECTURE.' \
  "spec" "M1 Norms" F2 >/dev/null

child_issue "Spec: Hash IDs/digests (BLAKE3 + SHA256 mirror)" \
  $'Define id_b3/id_sha256_mirror and state_b3/state_sha256_mirror; equality by BLAKE3.' \
  "spec,decision" "M1 Norms" F2 >/dev/null

child_issue "Spec: Policy determinism profile (hostless WASM)" \
  $'Define ABI I/O JSON, no WASI/syscalls, memory/fuel limits, no floats; env whitelist.' \
  "spec,decision" "M1 Norms" F2 >/dev/null

child_issue "Spec: Timestamp rules (ISO-8601 UTC; monotonic)" \
  $'Require ISO-8601 UTC; include in signed content; monotonic vs parent.' \
  "spec" "M1 Norms" F2 >/dev/null

child_issue "Spec: Canonical JSON (sorted keys; no floats)" \
  $'Define canonicalization procedure and signing exclusions; examples.' \
  "spec" "M1 Norms" F2 >/dev/null

child_issue "Spec: Proofs compaction + snapshot manifest" \
  $'Define append-only snapshots under refs/_ledger/<ns>/proofs/snapshots; snapshot.proof.json.' \
  "spec,decision" "M1 Norms" F2 >/dev/null

child_issue "Docs: Update ref layout diagrams (modes + compaction)" \
  $'Update Mermaid diagrams; ensure GitHub rendering; cross-links.' \
  "docs" "M1 Norms" F2 >/dev/null

# F1 Spec Freeze tasks
child_issue "SPEC.md normative pass (MUST/SHOULD/MAY) & remove markers" \
  $'Normalize terms; remove non-rendering admonitions; align with F2.' \
  "spec" "M2 Spec Freeze RC" F1 >/dev/null

child_issue "MODEL.md formulas + plain-text fallbacks" \
  $'Fix LaTeX and add readable fallbacks for GitHub view.' \
  "spec" "M2 Spec Freeze RC" F1 >/dev/null

child_issue "REFERENCE.md align IDs/digests + config keys + errors" \
  $'Sync API examples/fields; document config keys and error taxonomy.' \
  "spec" "M2 Spec Freeze RC" F1 >/dev/null

child_issue "ARCHITECTURE.md sync with modes + compaction" \
  $'Ref layout and diagrams updated to F2 decisions.' \
  "spec" "M2 Spec Freeze RC" F1 >/dev/null

child_issue "COMPLIANCE.md: mode selection + quorum (Core vs Extended)" \
  $'Core ≥1 attestation; Extended N-of-M (default 2-of-3); CLI contract.' \
  "spec,compliance" "M2 Spec Freeze RC" F1 >/dev/null

# F4 Schemas
child_issue "Schema: schemas/entry.json (canonical fields; no floats)" \
  $'Define entry schema; include canonical constraints and examples.' \
  "schema" "M3 Schemas+Examples" F4 >/dev/null

child_issue "Schema: schemas/attest.json (mode-agnostic)" \
  $'Support commit/notes/branch representations; signer/alg/signature/scope/time.' \
  "schema" "M3 Schemas+Examples" F4 >/dev/null

child_issue "Schema: schemas/proof.json (append/attest/policy/replay + snapshot)" \
  $'Include snapshot schema for compaction; examples.' \
  "schema" "M3 Schemas+Examples" F4 >/dev/null

child_issue "Schema: schemas/policy.json (metadata + ABI)" \
  $'Minimal metadata; link to determinism profile; IO contracts.' \
  "schema" "M3 Schemas+Examples" F4 >/dev/null

child_issue "Script: scripts/validate_schemas.sh (ajv/spectral)" \
  $'Local validation script; used by CI.' \
  "schema,ci" "M3 Schemas+Examples" F4 >/dev/null

child_issue "REFERENCE.md: schema usage + canonicalization notes" \
  $'Cross-reference schemas; explain canonicalization and signing.' \
  "spec,schema" "M3 Schemas+Examples" F4 >/dev/null

# F5 Examples
child_issue "Examples: proofs branch mode (end-to-end)" \
  $'Artifacts under examples/branch/: entry→attest→replay→proofs.' \
  "examples" "M3 Schemas+Examples" F5 >/dev/null

child_issue "Examples: proofs notes mode" \
  $'Artifacts under examples/notes/; include replication caveat.' \
  "examples" "M3 Schemas+Examples" F5 >/dev/null

child_issue "Examples: proofs private mode" \
  $'Artifacts under examples/private/; mark as non-replicated/non-normative.' \
  "examples" "M3 Schemas+Examples" F5 >/dev/null

child_issue "Examples: attestation via commit signature" \
  $'Signed commit example; show resolver output.' \
  "examples" "M3 Schemas+Examples" F5 >/dev/null

child_issue "Examples: attestation via notes and via attestation branch" \
  $'Illustrate both; resolver demonstration.' \
  "examples" "M3 Schemas+Examples" F5 >/dev/null

child_issue "Walkthrough: examples/replay_invariants.md" \
  $'Step-by-step replay narrative with invariant checks.' \
  "docs,examples" "M3 Schemas+Examples" F5 >/dev/null

# F3 Compliance (Core)
child_issue "Harness: tests/harness/run_tests.sh (mode-aware)" \
  $'Accept MODE=proofs:<mode>,attest:<mode>; run fixtures accordingly.' \
  "compliance,ci" "M4 Compliance MVP" F3 >/dev/null

child_issue "Verifier: tests/harness/verify_proofs.py (mode-aware)" \
  $'Validate proofs location, schema, and deterministic outcomes per mode.' \
  "compliance" "M4 Compliance MVP" F3 >/dev/null

for i in 01 02 03 04 05 06 07 08; do
  title="Fixture ${i}"
  case "$i" in
    01) desc="Append-Only: attempt modify/delete → reject";;
    02) desc="Fast-Forward: non-ancestor commit → reject";;
    03) desc="Deterministic Replay: two runs → identical state_b3";;
    04) desc="Attestation Verification: tamper → invalid";;
    05) desc="Policy Enforcement: WASM policy false → reject";;
    06) desc="Temporal Monotonicity: back-dated → reject";;
    07) desc="Namespace Isolation: cross-ref pollution prevented";;
    08) desc="Equivalence: identical sequences → equal states";;
  esac
  child_issue "Compliance: ${title} — ${desc}" \
    $'Create tests/compliance/'"${i}"$'_*.yaml fixture and referenced artifacts. Include Mode matrix for supported combinations.' \
    "compliance" "M4 Compliance MVP" F3 >/dev/null
done

# F3 Extended: quorum 2-of-3
child_issue "Extended: Quorum policy 2-of-3 + fixtures" \
  $'Define N-of-M policy with N=2, M=3. Provide pass and fail fixtures; document in COMPLIANCE Extended.' \
  "compliance" "M4 Compliance MVP" F3 >/dev/null

child_issue "Extended: Verifier checks quorum result in proofs" \
  $'Proofs include attestors that satisfied quorum; verifier asserts consistency.' \
  "compliance" "M4 Compliance MVP" F3 >/dev/null

# F6 Docs (VitePress)
child_issue "VitePress: scaffold site (config + index + nav)" \
  $'Add docs/.vitepress/config.ts and basic pages; local dev works.' \
  "site,docs" "M5 Docs+CI" F6 >/dev/null

child_issue "VitePress: convert admonitions + mermaid strategy" \
  $'Replace admonitions with VitePress syntax; enable mermaid plugin or static images.' \
  "site,docs" "M5 Docs+CI" F6 >/dev/null

child_issue "VitePress: Modes & Decisions pages" \
  $'Author /modes and /decisions with defaults + alternatives and rationale.' \
  "site,docs" "M5 Docs+CI" F6 >/dev/null

child_issue "VitePress: GH Pages workflow" \
  $'Build and deploy site on main branch; link from README.' \
  "site,ci" "M5 Docs+CI" F6 >/dev/null

child_issue "README cleanup and site link" \
  $'Fix tables; update Quick Start for this repo scope; add site link.' \
  "docs" "M5 Docs+CI" F6 >/dev/null

# F7 CI
child_issue "CI: markdown lint + spell check" \
  $'Add configs and job; allowlist spec terms.' \
  "ci" "M5 Docs+CI" F7 >/dev/null

child_issue "CI: link checker" \
  $'Ensure all internal/external links resolve.' \
  "ci" "M5 Docs+CI" F7 >/dev/null

child_issue "CI: schema validation job" \
  $'Run scripts/validate_schemas.sh in PRs.' \
  "ci,schema" "M5 Docs+CI" F7 >/dev/null

child_issue "CI: VitePress build check" \
  $'Ensure docs build succeeds in PRs.' \
  "ci,site" "M5 Docs+CI" F7 >/dev/null

child_issue "CI: Mermaid render or fallback images" \
  $'Validate diagrams; if not supported, pre-render PNGs.' \
  "ci,site" "M5 Docs+CI" F7 >/dev/null

# F8 Governance
child_issue "CHANGELOG.md (0.1.0→1.0.0)" \
  $'Create and populate changelog with notable decisions.' \
  "governance" "M6 Governance+Security" F8 >/dev/null

child_issue "Version negotiation + _meta/version guidance" \
  $'Document refs/_ledger/_meta/version content and lifecycle.' \
  "governance,spec" "M6 Governance+Security" F8 >/dev/null

child_issue "Release process doc (tagging, signing, publish)" \
  $'Add step-by-step release checklist for 1.0.0.' \
  "governance" "M6 Governance+Security" F8 >/dev/null

child_issue "Spec freeze process (exclusive window)" \
  $'Define editor role, LGTM rules, and freeze window mechanics.' \
  "governance" "M6 Governance+Security" F8 >/dev/null

# F9 Security
child_issue "SECURITY.md (contact, timelines)" \
  $'Responsible disclosure and contact details.' \
  "security" "M6 Governance+Security" F9 >/dev/null

child_issue "Threat model doc" \
  $'Tampering, replay, time skew, policy bypass; mitigations; residual risks.' \
  "security,docs" "M6 Governance+Security" F9 >/dev/null

child_issue "Key guidance (Ed25519, rotation, trust roots, quorum)" \
  $'Operational advice for implementers and auditors.' \
  "security,docs" "M6 Governance+Security" F9 >/dev/null

# F10 Community
child_issue "CONTRIBUTING.md" \
  $'Contribution scope, docs style, decision change process.' \
  "governance,templates" "M6 Governance+Security" F10 >/dev/null

child_issue "CODE_OF_CONDUCT.md" \
  $'Adopt a standard code of conduct.' \
  "governance,templates" "M6 Governance+Security" F10 >/dev/null

child_issue "Issue templates (Bug, Spec Change, Docs, Compliance)" \
  $'Under .github/ISSUE_TEMPLATE/ with fields for versions and mode.' \
  "governance,templates" "M6 Governance+Security" F10 >/dev/null

child_issue "PR template (schema validates, links checked, decisions referenced)" \
  $'Checklist to keep quality high.' \
  "governance,templates" "M6 Governance+Security" F10 >/dev/null

child_issue "Labels guide (Labels.md)" \
  $'Explain label taxonomy and usage conventions.' \
  "governance,templates" "M6 Governance+Security" F10 >/dev/null

info "Backlog creation completed."
