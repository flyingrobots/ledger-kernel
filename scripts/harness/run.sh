#!/usr/bin/env bash
# Minimal polyglot compliance orchestrator
# - Reads a TOML config describing checks (C-1..C-5), clauses, and CLI commands
# - Runs each check with timeout/sandboxing
# - Builds a consolidated compliance.json
# - Validates report against schemas/compliance_report.schema.json (best-effort)

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

CONF="$HERE/config.sample.toml"
OUT_JSON="$PWD/compliance.json"
SCHEMA_DEFAULT="$ROOT/schemas/compliance_report.schema.json"
SCHEMA="$SCHEMA_DEFAULT"
LEVEL="all"   # core|policy|wasm|all
TIMEOUT_DEFAULT=30

usage() {
  cat <<EOF
Usage: $(basename "$0") [--config file.toml] [--output compliance.json] [--schema schema.json] [--level core|policy|wasm|all]

Examples:
  $(basename "$0") --config $HERE/config.sample.toml --output compliance.json --level core
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config) CONF="$2"; shift 2;;
    -o|--output) OUT_JSON="$2"; shift 2;;
    -s|--schema) SCHEMA="$2"; shift 2;;
    -l|--level)  LEVEL="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 2; }

if [[ ! -f "$CONF" ]]; then
  echo "ERROR: config file not found: $CONF" >&2
  exit 2
fi

# --- Tiny TOML reader for expected shape ---
# Supports:
# [orchestrator]\nkey = "value"\n
# [checks.C-1]\nclause = ["FS-10"]\ncmd = "..."\nlevel = "core"\ntimeout = 30

impl_name=""
impl_version=""
global_timeout=$TIMEOUT_DEFAULT

mapfile -t raw_lines < <(sed -e 's/#.*$//' -e 's/[\r\t]//g' "$CONF" | awk 'NF')

current_section=""
declare -A check_cmd
declare -A check_clause
declare -A check_level
declare -A check_timeout

for line in "${raw_lines[@]}"; do
  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    current_section="${BASH_REMATCH[1]}"
    continue
  fi
  key="${line%%=*}"; key="${key// /}"
  val="${line#*=}"
  val="${val## }"; val="${val%% }"
  # strip surrounding quotes for simple strings
  if [[ "$val" =~ ^"(.*)"$ ]]; then val="${BASH_REMATCH[1]}"; fi

  case "$current_section" in
    orchestrator)
      case "$key" in
        implementation) impl_name="$val";;
        version) impl_version="$val";;
        timeout_sec) global_timeout="$val";;
      esac
      ;;
    checks.*)
      cid="${current_section#checks.}"
      case "$key" in
        cmd) check_cmd["$cid"]="$val";;
        level) check_level["$cid"]="$val";;
        timeout) check_timeout["$cid"]="$val";;
        clause)
          # normalize array of strings: ["FS-7","FS-8"] -> FS-7,FS-8
          arr="$val"
          arr="${arr#[}"
          arr="${arr%]}"
          arr="${arr//\"/}"
          arr="${arr// /}"
          check_clause["$cid"]="$arr"
          ;;
      esac
      ;;
  esac
done

if [[ -z "$impl_name" ]]; then impl_name="unknown"; fi
if [[ -z "$impl_version" ]]; then impl_version="0.0.0"; fi

# --- Execute checks ---

tmpdir="$(mktemp -d)"; trap 'rm -rf "$tmpdir"' EXIT
results_json="$tmpdir/results.json"
echo '[]' > "$results_json"

status_to_json() {
  case "$1" in
    PASS|PARTIAL|FAIL|N/A) echo "$1";;
    0) echo PASS;;
    64) echo PARTIAL;;
    124) echo FAIL;;
    *) echo FAIL;;
  esac
}

append_result() {
  local id="$1"; shift
  local clauses_csv="$1"; shift
  local status="$1"; shift
  local notes="$1"; shift || true
  # convert clauses_csv -> JSON array
  local clauses_json
  if [[ -z "$clauses_csv" ]]; then
    clauses_json='[]'
  else
    clauses_json="[\"${clauses_csv//,/\",\"}\"]"
  fi
  jq --arg id "$id" \
     --arg status "$status" \
     --arg notes "$notes" \
     --argjson clauses "$clauses_json" \
     '. += [{id:$id, clause: clauses, status:$status} + ( $notes|length>0 ? {notes:$notes} : {} )]' "$results_json" > "$results_json.tmp"
  mv "$results_json.tmp" "$results_json"
}

run_one() {
  local id="$1"; local level_hint="$2"; local cmd="$3"; local clauses_csv="$4"; local to_sec="$5"
  # level filter
  if [[ "$LEVEL" != "all" && "$level_hint" != "$LEVEL" ]]; then
    append_result "$id" "$clauses_csv" "N/A" "skipped by --level=$LEVEL"
    return
  fi
  local t=${to_sec:-$global_timeout}
  ulimit -c 0 || true
  local out err rc
  out="$tmpdir/$id.out"; err="$tmpdir/$id.err"
  if command -v timeout >/dev/null 2>&1; then
    bash -c "timeout $t bash -c '$cmd'" >"$out" 2>"$err" || rc=$?
  else
    bash -c "$cmd" >"$out" 2>"$err" || rc=$?
  fi
  rc=${rc:-0}
  local status
  status=$(status_to_json "$rc")
  # trim notes from stderr (last line)
  local note=""
  if [[ -s "$err" ]]; then note="$(tail -n1 "$err" | sed 's/\r$//')"; fi
  append_result "$id" "$clauses_csv" "$status" "$note"
}

# Iterate checks as declared in config order
for key in "${!check_cmd[@]}"; do
  lvl="${check_level[$key]:-core}"
  clauses="${check_clause[$key]:-}"
  to="${check_timeout[$key]:-}"
  run_one "$key" "$lvl" "${check_cmd[$key]}" "$clauses" "$to"
done

# --- Build consolidated report ---

utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# compute summaries per level
compute_summary_level() {
  local level="$1"
  # filter results that belong to this level by config lookup
  local statuses=()
  for id in "${!check_cmd[@]}"; do
    local lvl="${check_level[$id]:-core}"
    if [[ "$lvl" == "$level" ]]; then
      local st
      st=$(jq -r ".[] | select(.id==\"$id\") | .status" "$results_json" | tail -n1)
      statuses+=("${st:-N/A}")
    fi
  done
  if [[ ${#statuses[@]} -eq 0 ]]; then echo "N/A"; return; fi
  local any_fail any_partial all_na
  any_fail=0; any_partial=0; all_na=1
  for s in "${statuses[@]}"; do
    [[ "$s" != "N/A" ]] && all_na=0
    [[ "$s" == "FAIL" ]] && any_fail=1
    [[ "$s" == "PARTIAL" ]] && any_partial=1
  done
  if [[ $all_na -eq 1 ]]; then echo "N/A"; return; fi
  if [[ $any_fail -eq 1 ]]; then echo "FAIL"; return; fi
  if [[ $any_partial -eq 1 ]]; then echo "PARTIAL"; return; fi
  echo "PASS"
}

summary_core=$(compute_summary_level core)
summary_policy=$(compute_summary_level policy)
summary_wasm=$(compute_summary_level wasm)

jq -n \
  --arg impl "$impl_name" \
  --arg ver  "$impl_version" \
  --arg date "$(utc)" \
  --slurpfile results "$results_json" \
  --arg core   "$summary_core" \
  --arg policy "$summary_policy" \
  --arg wasm   "$summary_wasm" \
  '{implementation:$impl, version:$ver, date:$date, results:$results[0], summary:{core:$core, policy:$policy, wasm:$wasm}}' \
  > "$OUT_JSON"

echo "Wrote report: $OUT_JSON"

# --- Validate report (best-effort) ---
validate_ok=0
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' "$SCHEMA" "$OUT_JSON" && exit 0 || exit 1
import json, sys
try:
  import jsonschema
except Exception:
  sys.exit(1)
with open(sys.argv[1]) as s: schema=json.load(s)
with open(sys.argv[2]) as f: data=json.load(f)
jsonschema.validate(data, schema)
print("Schema validation: OK")
PY
  validate_ok=$?
fi
if [[ $validate_ok -ne 0 ]]; then
  # fallback: structural checks via jq
  jq -e '.implementation and .version and .date and (.results|type=="array") and (.summary.core and .summary.policy and .summary.wasm)' "$OUT_JSON" >/dev/null && echo "Basic structure: OK" || { echo "Basic structure: FAIL" >&2; exit 1; }
fi

# Exit non-zero if a requested level failed
if [[ "$LEVEL" != "all" ]]; then
  verdict=$(jq -r ".summary.$LEVEL" "$OUT_JSON")
  [[ "$verdict" == "PASS" ]] || { echo "Requested level failed: $verdict" >&2; exit 1; }
fi

exit 0

