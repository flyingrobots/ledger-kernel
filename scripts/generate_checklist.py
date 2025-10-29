#!/usr/bin/env python3
import json, subprocess, sys, datetime

ORDERED_MILESTONES = [
    "M0 Repo Hygiene",
    "M1 Norms",
    "M2 Spec Freeze RC",
    "M3 Schemas+Examples",
    "M4 Compliance MVP",
    "M5 Docs+CI",
    "M6 Governance+Security",
    "v1.0.0",
]


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


def list_issues(milestone: str, state: str = "open"):
    # gh issue list supports --milestone
    return sh_json(["gh", "issue", "list", "--state", state, "--limit", "500", "--milestone", milestone,
                    "--json", "number,title,state,url,labels,milestone"]) or []


def is_epic(issue):
    return any(l.get("name") == "epic" for l in (issue.get("labels") or []))


def blocked_by(repo, number):
    j = sh_json(["gh", "api", f"repos/{repo}/issues/{number}"])
    s = (j.get("issue_dependencies_summary") or {})
    total = s.get("total_blocked_by") or s.get("blocked_by") or 0
    return int(total)


def main():
    repo = repo_name()
    now = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    out = []
    out.append("# Ledger-Kernel 1.0.0 — Execution Checklist")
    out.append("")
    out.append(f"Generated from GitHub Issues on {now}.")
    out.append("")
    out.append("## Phase Order (Hard Dependencies)")
    out.append("- M0 → M1 → M2 → M3 → M4 → M5 → M6 → v1.0.0")
    out.append("")

    for ms in ORDERED_MILESTONES:
        open_issues = [i for i in list_issues(ms, state="open") if not is_epic(i)]
        closed_issues = [i for i in list_issues(ms, state="closed") if not is_epic(i)]
        if not open_issues and not closed_issues:
            continue
        out.append(f"## {ms}")
        out.append("")
        if closed_issues:
            out.append("### Done")
            for it in sorted(closed_issues, key=lambda x: x["number"]):
                out.append(f"- [x] [{it['title']}]({it['url']}) (#{it['number']})")
            out.append("")
        if open_issues:
            out.append("### Next")
            for it in sorted(open_issues, key=lambda x: x["number"]):
                try:
                    bb = blocked_by(repo, it["number"])
                except Exception:
                    bb = 0
                block_note = f" ⛓ blocked ({bb})" if bb else ""
                out.append(f"- [ ] [{it['title']}]({it['url']}) (#{it['number']}){block_note}")
            out.append("")

    path = "docs/checklist.md"
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"Wrote {path}")


if __name__ == "__main__":
    main()

