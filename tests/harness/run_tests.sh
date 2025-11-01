#!/usr/bin/env bash
set -euo pipefail

# Minimal compliance harness runner.
# Discovers YAML cases and drives an implementation CLI, or runs in noop/skip mode.

usage() {
  cat <<EOF
Usage: run_tests.sh [--impl <path>|noop] [--mode branch|notes|private] [--fixtures-glob <glob>] [--junit <file>]

Options:
  --impl           Path to implementation binary to test, or 'noop' to skip execution (default: noop)
  --mode           Ledger mode to pass through to implementation (default: branch)
  --fixtures-glob  Glob for test cases (default: tests/compliance/*.yaml)
  --junit          Optional JUnit XML output path (summary only)

Notes:
- Placeholder YAMLs (empty or comment-only) are auto-skipped.
- In 'noop' mode, cases are discovered and reported as SKIP; exit code is 0.
EOF
}

impl="noop"
mode="branch"
glob="tests/compliance/*.yaml"
junit=""

# Require that an option is followed by a non-empty value that does not
# look like another flag (i.e., not starting with '-').
require_value() {
  local opt="$1"; local val="${2-}"
  if [[ -z "${val:-}" || "${val}" == -* ]]; then
    echo "ERROR: $opt requires a value" >&2
    usage
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --impl)
      require_value "--impl" "${2-}"
      impl="$2"; shift 2;;
    --mode)
      require_value "--mode" "${2-}"
      mode="$2";
      case "$mode" in
        branch|notes|private) :;;
        *) echo "ERROR: invalid --mode '$mode' (allowed: branch|notes|private)" >&2; usage; exit 2;;
      esac
      shift 2;;
    --fixtures-glob)
      require_value "--fixtures-glob" "${2-}"
      glob="$2"; shift 2;;
    --junit)
      require_value "--junit" "${2-}"
      junit="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

shopt -s nullglob
total=0; passed=0; failed=0; skipped=0
results_lines=""

is_placeholder() {
  local f="$1"
  # Non-empty, non-comment lines count as content.
  if grep -qE '^[[:space:]]*[^#[:space:]]' "$f"; then
    return 1 # has content
  else
    return 0 # placeholder
  fi
}

run_case() {
  local f="$1"
  total=$((total+1))
  if is_placeholder "$f"; then
    results_lines+="SKIP $f placeholder\n"
    skipped=$((skipped+1))
    return 0
  fi
  if [[ "$impl" == "noop" ]]; then
    results_lines+="SKIP $f noop\n"
    skipped=$((skipped+1))
    return 0
  fi
  # Execute implementation in verify mode. Proof dir is optional future extension.
  if "$impl" --verify "$f" --mode "$mode"; then
    results_lines+="PASS $f\n"
    passed=$((passed+1))
  else
    results_lines+="FAIL $f\n"
    failed=$((failed+1))
  fi
}

# Validate implementation once up front (fail fast) when not in noop mode.
if [[ "$impl" != "noop" ]]; then
  if [[ ! -x "$impl" && ! -f "$impl" ]]; then
    echo "ERROR: --impl '$impl' not found or not executable" >&2
    exit 2
  fi
fi

found_any=0
for f in $glob; do
  found_any=1
  if ! run_case "$f"; then
    rc=$?
    echo "Aborting (rc=$rc)" >&2
    exit "$rc"
  fi
done

if [[ "$found_any" -eq 0 ]]; then
  echo "No cases match glob: $glob"
  exit 0
fi

printf "\nSummary: total=%d passed=%d failed=%d skipped=%d mode=%s\n" "$total" "$passed" "$failed" "$skipped" "$mode"
printf "\nDetails:\n"
printf "%b" "$results_lines"

if [[ -n "$junit" ]]; then
  ts=$(date +%s)
  junit_dir="$(dirname "$junit")"
  if ! mkdir -p "$junit_dir"; then
    echo "ERROR: failed to create JUnit directory: $junit_dir" >&2
    exit 2
  fi

  # Escape for XML attribute contexts.
  xml_escape_attr() {
    # shellcheck disable=SC2016
    printf '%s' "$1" | sed \
      -e 's/&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g' \
      -e 's/"/\&quot;/g' \
      -e "s/'/\&apos;/g"
  }
  {
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    echo "<testsuite name=\"ledger-kernel-compliance\" tests=\"$total\" failures=\"$failed\" skipped=\"$skipped\" timestamp=\"$ts\">"
    while IFS= read -r line; do
      # Expect at least two tokens: STATUS and FILE
      status=$(printf '%s' "$line" | awk '{print $1}')
      file=$(printf '%s' "$line" | awk '{print $2}')
      if [[ -z "$status" || -z "$file" ]]; then continue; fi
      class_esc=$(xml_escape_attr "compliance")
      name_esc=$(xml_escape_attr "$file")
      echo "  <testcase classname=\"$class_esc\" name=\"$name_esc\">"
      if [[ "$status" == "FAIL" ]]; then
        echo "    <failure message=\"failed\"/>"
      elif [[ "$status" == "SKIP" ]]; then
        echo "    <skipped/>"
      fi
      echo "  </testcase>"
    done <<< "$(printf '%b' "$results_lines")"
    echo "</testsuite>"
  } > "$junit"
  echo "Wrote JUnit: $junit"
fi

# Exit non-zero if any failures occurred.
if [[ "$failed" -gt 0 ]]; then
  exit 1
else
  exit 0
fi
