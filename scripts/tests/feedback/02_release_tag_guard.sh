#!/usr/bin/env bash
set -euo pipefail
f=.github/workflows/release.yml
# Check a tags line contains a strict semver-like pattern
rg -n "^\s*tags:\s*$" "$f" >/dev/null
rg -n "^\s*- 'v[0-9]+\.[0-9]+\.[0-9]+'" "$f" >/dev/null
# Check we guard by ref_type/startsWith
rg -n "^\s*if:\s*github.ref_type == 'tag'.*startsWith\(github.ref, 'refs/tags/v'\)" "$f" >/dev/null
