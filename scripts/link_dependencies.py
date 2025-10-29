#!/usr/bin/env python3
import json, subprocess, sys


def sh_json(args):
    p = subprocess.run(args, text=True, capture_output=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr or p.stdout)
    return json.loads(p.stdout)


def sh(args):
    p = subprocess.run(args, text=True, capture_output=True)
    return p.returncode, p.stdout, p.stderr


def repo_name():
    p = subprocess.run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"], text=True, capture_output=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr or p.stdout)
    return p.stdout.strip()


def get_issue_numeric_id(repo, number):
    j = sh_json(["gh", "api", f"repos/{repo}/issues/{number}"])
    return j.get("id")


def add_blocked_by(repo, blocked_number, blocking_number):
    blocking_id = get_issue_numeric_id(repo, blocking_number)
    if not blocking_id:
        return False, f"no id for #{blocking_number}"
    payload = json.dumps({"issue_id": int(blocking_id)})
    rc, out, err = sh([
        "gh", "api", "-X", "POST",
        f"repos/{repo}/issues/{blocked_number}/dependencies/blocked_by",
        "-H", "Accept: application/vnd.github+json",
        "-H", "Content-Type: application/json",
        "--input", "-"
    ],)
    if rc == 0:
        return True, "linked"
    # If first try didn't send body, try again piping payload
    rc2 = subprocess.run([
        "gh", "api", "-X", "POST",
        f"repos/{repo}/issues/{blocked_number}/dependencies/blocked_by",
        "-H", "Accept: application/vnd.github+json",
        "-H", "Content-Type: application/json",
        "--input", "-"
    ], input=payload, text=True, capture_output=True)
    if rc2.returncode == 0:
        return True, "linked"
    out = rc2.stdout
    err = rc2.stderr
    if rc == 0:
        return True, "linked"
    # Ignore duplication errors
    if "already exists" in (err or out):
        return True, "exists"
    # If API not enabled
    return False, (err or out)


def list_issues():
    return sh_json(["gh", "issue", "list", "--state", "open", "--limit", "200",
                    "--json", "number,title,labels,milestone"])


def has_label(issue, name):
    return any(l.get("name") == name for l in (issue.get("labels") or []))


def main():
    repo = repo_name()
    issues = list_issues()

    # Index by number
    idx = {i["number"]: i for i in issues}

    # Helper filters
    def milestone(name):
        return [i for i in issues if (i.get("milestone") or {}).get("title") == name]

    def titled(prefix):
        return [i for i in issues if i.get("title", "").startswith(prefix)]

    # Sets
    norms_tasks = [i for i in milestone("M1 Norms") if (has_label(i, "spec") or has_label(i, "decision") or i["title"].startswith(("Spec:", "Config:", "Docs: Update ref layout")))]
    spec_freeze_tasks = milestone("M2 Spec Freeze RC")

    schema_tasks = [i for i in milestone("M3 Schemas+Examples") if (has_label(i, "schema") or i["title"].startswith(("Schema:", "Script: scripts/validate_schemas.sh", "REFERENCE.md:")))]
    compliance_tasks = [i for i in milestone("M4 Compliance MVP") if (has_label(i, "compliance") or i["title"].startswith(("Compliance:", "Harness:", "Verifier:")))]

    links = []

    # Epic-level links (hard deps)
    epic_links = [
        (3, 2),  # F1 Spec blocked by F2 Norms
        (4, 2),  # F4 Schemas blocked by F2 Norms
        (6, 2),  # F3 Compliance blocked by F2 Norms
        (6, 4),  # F3 Compliance blocked by F4 Schemas
        (7, 3),  # F6 Docs blocked by F1 Spec Freeze
        (8, 7),  # F7 CI blocked by Docs site
    ]
    links.extend(epic_links)

    # Task-level links
    for t in spec_freeze_tasks:
        for n in norms_tasks:
            links.append((t["number"], n["number"]))

    for t in compliance_tasks:
        for s in schema_tasks:
            links.append((t["number"], s["number"]))

    # Deduplicate
    seen = set()
    links_u = []
    for a, b in links:
        if (a, b) not in seen:
            links_u.append((a, b))
            seen.add((a, b))

    ok = 0
    fail = 0
    for blocked, blocking in links_u:
        success, msg = add_blocked_by(repo, blocked, blocking)
        if success:
            ok += 1
        else:
            fail += 1
        print(f"#{blocked} blocked by #{blocking}: {msg}")

    print(f"Done. Linked {ok}, failed {fail}.")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
