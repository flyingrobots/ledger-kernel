#!/usr/bin/env python3
import json, subprocess, sys


def sh_json(args):
    p = subprocess.run(args, text=True, capture_output=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr or p.stdout)
    return json.loads(p.stdout)


def repo_name():
    p = subprocess.run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], text=True, capture_output=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr or p.stdout)
    return p.stdout.strip()


def list_open_issues():
    return sh_json(["gh", "issue", "list", "--state", "open", "--limit", "200",
                    "--json", "number,title,labels,milestone"])


def has_label(issue, name):
    return any(l.get("name") == name for l in (issue.get("labels") or []))


def comments_for(repo, number):
    return sh_json(["gh", "api", f"repos/{repo}/issues/{number}/comments"])


def add_comment(repo, number, body):
    return sh_json(["gh", "api", "-X", "POST", f"repos/{repo}/issues/{number}/comments",
                    "-H", "Accept: application/vnd.github+json", "-f", f"body={body}"])


MARKER = "[soft-deps] v1"


def ensure_comment(repo, issue, body):
    number = issue["number"]
    try:
        cmts = comments_for(repo, number)
    except Exception:
        cmts = []
    for c in cmts:
        if MARKER in (c.get("body") or ""):
            return False
    add_comment(repo, number, f"{MARKER}\n\n{body}")
    return True


def main():
    repo = repo_name()
    issues = list_open_issues()

    # Index issues by milestone and label
    m = {}
    for it in issues:
        ms = (it.get("milestone") or {}).get("title")
        m.setdefault(ms, []).append(it)

    updated = 0

    # M3 Schemas+Examples: soft on #3
    for it in m.get("M3 Schemas+Examples", []):
        body = "This task has a soft dependency on #3 (Spec Freeze RC): finalizing terminology and IDs/digests improves schema stability and docs alignment, but does not strictly block execution."
        if ensure_comment(repo, it, body):
            updated += 1

    # M4 Compliance MVP: soft on #5
    for it in m.get("M4 Compliance MVP", []):
        body = "This task has a soft dependency on #5 (Examples Pack): richer example artifacts improve fixture coverage and comprehension, but are not strictly required for the compliance harness."
        if ensure_comment(repo, it, body):
            updated += 1

    # M5 Docs+CI: docs/site tasks soft on #4 and #5; CI tasks soft on #4 and #6
    for it in m.get("M5 Docs+CI", []):
        title = it.get("title", "")
        if has_label(it, "site") or has_label(it, "docs") or title.startswith("VitePress:"):
            body = "This task has soft dependencies on #4 (JSON Schemas) and #5 (Examples Pack): stable schemas and examples improve documentation accuracy and navigation, but do not strictly block site setup."
        elif has_label(it, "ci") or title.startswith("CI:"):
            body = "This task has soft dependencies on #4 (JSON Schemas) and #6 (Compliance Suite v1): schema files and harness fixtures enable the related CI jobs, but the CI scaffolding itself can land earlier."
        else:
            continue
        if ensure_comment(repo, it, body):
            updated += 1

    # M6 Governance+Security: soft on M2–M5 epics
    for it in m.get("M6 Governance+Security", []):
        body = "This task has soft dependencies on #3 (Spec Freeze RC), #4 (JSON Schemas), #5 (Examples Pack), #6 (Compliance Suite v1), #7 (Docs Site), and #8 (CI & Validation): governance and security docs reference these outputs, but drafting can begin in parallel."
        if ensure_comment(repo, it, body):
            updated += 1

    # Epic-level soft notes
    epic_map = {
        4: "Epic-level soft dependency on #3 (Spec Freeze RC): spec harmonization improves schema docs.",
        6: "Epic-level soft dependency on #5 (Examples Pack): examples improve fixture quality and verification guidance.",
        7: "Epic-level soft dependencies on #4 (JSON Schemas) and #5 (Examples Pack): site content quality improves once these exist.",
        8: "Epic-level soft dependencies on #4 (JSON Schemas) and #6 (Compliance Suite v1): CI jobs will validate these when present.",
        10: "Epic-level soft dependencies on #2 (Norms & Conventions) and #3 (Spec Freeze RC): definitions and harmonized terms inform the threat model and security posture.",
        12: "Epic-level soft dependency on #3 (Spec Freeze RC): contributor templates reference stabilized terminology."
    }

    by_number = {it["number"]: it for it in issues}
    for num, note in epic_map.items():
        it = by_number.get(num)
        if not it:
            continue
        if ensure_comment(repo, it, note):
            updated += 1

    print(f"Soft-dependency comments added: {updated}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

