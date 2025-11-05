#!/usr/bin/env python3
"""
Spec linter:
- recomputes id from canonical preimage (entry without attestations)
- prints expected signing input ("ledger-entry:" + id)
- validates compliance.json against schema (if provided)
"""
import sys, json, argparse
from pathlib import Path

def canonical(v):
    if isinstance(v, dict):
        items = sorted(v.items(), key=lambda kv: kv[0])
        return '{' + ','.join([json.dumps(k, ensure_ascii=False)+":"+canonical(x) for k,x in items]) + '}'
    if isinstance(v, list):
        return '[' + ','.join([canonical(x) for x in v]) + ']'
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        raise SystemExit("ERROR: floats are forbidden in canonical positions; encode as string")
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    raise SystemExit(f"ERROR: unsupported type {type(v)}")

def preimage(entry):
    e = dict(entry)
    e.pop('attestations', None)
    return canonical(e).encode('utf-8')

def b3_hex(data: bytes) -> str:
    try:
        import blake3
    except Exception:
        raise SystemExit("ERROR: python module 'blake3' not installed; pip install blake3")
    return blake3.blake3(data).hexdigest()

def validate_schema(report: Path, schema: Path) -> bool:
    try:
        import jsonschema
    except Exception:
        print("WARN: jsonschema not installed; skipping schema validation", file=sys.stderr)
        return False
    with report.open('r', encoding='utf-8') as f: data = json.load(f)
    with schema.open('r', encoding='utf-8') as s: sch = json.load(s)
    jsonschema.validate(data, sch)
    return True

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--entry', help='Entry JSON to lint')
    ap.add_argument('--report', help='compliance.json to validate')
    ap.add_argument('--schema', help='schema to validate report against', default='schemas/compliance_report.schema.json')
    args = ap.parse_args()

    if args.entry:
        data = json.loads(Path(args.entry).read_text(encoding='utf-8'))
        pid = b3_hex(preimage(data))
        print(f"computed_id={pid}")
        print(f"expected_signing_input=ledger-entry:{pid}")
        if 'id' in data and data['id'] and data['id'] != pid:
            print(f"DIFF: entry.id != computed id\n  entry.id    = {data['id']}\n  computed_id = {pid}")

    if args.report:
        ok = validate_schema(Path(args.report), Path(args.schema))
        if ok:
            print("report_schema=OK")

if __name__ == '__main__':
    main()

