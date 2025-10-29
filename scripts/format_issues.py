#!/usr/bin/env python3
import json, os, re, subprocess, sys, tempfile


def sh(*args, input=None):
    return subprocess.run(args, input=input, text=True, capture_output=True, check=False)


def gh_json(args):
    p = sh("gh", *args,)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or p.stdout)
    return json.loads(p.stdout)


def has_label(labels, name):
    names = [l.get("name", "") for l in (labels or [])]
    return name in names


def acceptance_for(title):
    t = title.strip()
    bullets = []
    if re.match(r"^Compliance: Fixture \\d+", t):
        bullets = [
            "YAML fixture exists under tests/compliance/ and validates against schema",
            "Includes Mode matrix for supported proofs/attest modes",
            "Reviewed and linked from COMPLIANCE.md",
        ]
    elif t.startswith("Harness:"):
        bullets = [
            "tests/harness/run_tests.sh accepts MODE=proofs:<mode>,attest:<mode>",
            "Runs fixtures and exits non-zero on failure",
            "Documented usage in COMPLIANCE.md",
        ]
    elif t.startswith("Verifier:"):
        bullets = [
            "tests/harness/verify_proofs.py validates proofs location per selected mode",
            "Validates JSON against proofs schema and checks determinism",
        ]
    elif t.startswith("VitePress:"):
        bullets = [
            "Site builds locally and in CI",
            "Mermaid diagrams render",
            "Navigation links present and correct",
        ]
    elif t.startswith("CI:"):
        bullets = [
            "Workflow file present under .github/workflows/",
            "Runs on pull_request and push to main",
            "Job passes on current main branch",
        ]
    elif t.startswith("README cleanup"):
        bullets = [
            "README tables render on GitHub",
            "Site link present and correct",
        ]
    elif t.startswith("Extended: Quorum"):
        bullets = [
            "Policy parameterized for N=2, M=3",
            "Provide pass and fail fixtures",
            "Verifier checks quorum outcome in proofs",
        ]
    elif t.startswith("Spec:"):
        bullets = [
            "SPEC/REFERENCE/ARCHITECTURE updated consistently",
            "Examples added where relevant",
        ]
    elif t.startswith("Config:"):
        bullets = [
            "refs/_ledger/_meta/config.json keys documented",
            "Defaults specified and cross-referenced",
        ]
    elif t.startswith("Docs: Update ref layout diagrams"):
        bullets = [
            "Mermaid diagrams updated and render on GitHub",
            "Referenced from ARCHITECTURE.md",
        ]
    elif t.startswith("Schema:"):
        bullets = [
            "Schema file added under schemas/",
            "Validates example artifacts",
        ]
    elif t.startswith("Script: scripts/validate_schemas.sh"):
        bullets = [
            "Script validates all schemas and examples",
            "Exit code non-zero on validation failure",
        ]
    elif t.startswith("REFERENCE.md:"):
        bullets = [
            "Section added with schema usage and canonicalization notes",
            "Cross-links resolve",
        ]
    elif t.startswith("Examples:"):
        bullets = [
            "Artifacts added under examples/…",
            "Narrative or README explains how to run/verify",
        ]
    elif t.startswith("Walkthrough:"):
        bullets = [
            "examples/replay_invariants.md added",
            "Steps reproduce deterministically",
        ]
    elif t.startswith("CHANGELOG.md"):
        bullets = [
            "CHANGELOG.md present with entries for 0.1.0→1.0.0",
        ]
    elif t.startswith("Version negotiation"):
        bullets = [
            "Document format of refs/_ledger/_meta/version",
            "Guidance for creation and updates",
        ]
    elif t.startswith("Release process"):
        bullets = [
            "Document tagging, signing, and publish steps",
        ]
    elif t.startswith("Spec freeze process"):
        bullets = [
            "Editor role and exclusive merge window documented",
            "Approval rules defined",
        ]
    elif t.startswith("SECURITY.md"):
        bullets = [
            "SECURITY.md added with contact and timelines",
        ]
    elif t.startswith("Threat model"):
        bullets = [
            "Document covers tamper/replay/time skew/policy bypass",
            "Mitigations and residual risks stated",
        ]
    elif t.startswith("Key guidance"):
        bullets = [
            "Operational guidance on Ed25519, rotation, trust roots, quorum",
        ]
    elif t in ("CONTRIBUTING.md", "CODE_OF_CONDUCT.md") or t.startswith("CONTRIBUTING") or t.startswith("CODE_OF_CONDUCT"):
        bullets = [
            "File added with appropriate content",
        ]
    elif t.startswith("Issue templates"):
        bullets = [
            "Templates added under .github/ISSUE_TEMPLATE/",
            "Fields include versions and mode",
        ]
    elif t.startswith("PR template"):
        bullets = [
            ".github/pull_request_template.md added",
            "Checklist includes schema validation and link check",
        ]
    elif t.startswith("Labels guide"):
        bullets = [
            "Labels.md added explaining taxonomy and usage",
        ]
    else:
        bullets = ["Deliverable present and reviewed", "Linked from relevant docs or CI"]
    return bullets


def main():
    issues = gh_json(["issue", "list", "--state", "open", "--limit", "200", "--json", "number,title,labels"])
    for it in issues:
        num = it["number"]
        title = it.get("title", "")
        labels = it.get("labels", [])
        if has_label(labels, "epic"):
            continue
        # Fetch body
        body = gh_json(["issue", "view", str(num), "--json", "body"]) .get("body", "")
        if body is None:
            body = ""
        # Normalize escaped \n
        body = body.replace("\\n", "\n")
        # Extract and remove Parent line
        parent_line = None
        lines = [ln for ln in body.splitlines() if ln.strip() != ""]
        new_lines = []
        for ln in lines:
            if ln.strip().lower().startswith("parent: #") and parent_line is None:
                parent_line = ln.strip()
            else:
                new_lines.append(ln)
        content = "\n".join(new_lines).strip()
        # If already has Acceptance and Links, skip
        if "### Acceptance" in content and "### Links" in content:
            continue
        # Ensure Context header
        if not content.startswith("### "):
            content = f"### Context\n{content}" if content else "### Context\n(see title)"
        # Ensure Acceptance section
        if "### Acceptance" not in content:
            bullets = acceptance_for(title)
            acc = "\n".join(f"- {b}" for b in bullets)
            content = f"{content}\n\n### Acceptance\n{acc}"
        # Ensure Links section
        links = []
        if parent_line:
            links.append(f"- {parent_line}")
        links_s = "\n".join(links) if links else "- N/A"
        content = f"{content}\n\n### Links\n{links_s}\n"
        # Write temp file and update
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".md") as tf:
            tf.write(content)
            path = tf.name
        r = sh("gh", "issue", "edit", str(num), "--body-file", path)
        os.unlink(path)
        if r.returncode != 0:
            print(f"warn: failed to update #{num}: {r.stderr or r.stdout}", file=sys.stderr)


if __name__ == "__main__":
    main()

