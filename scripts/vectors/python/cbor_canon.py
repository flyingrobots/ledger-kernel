#!/usr/bin/env python3
import sys, json
try:
    import cbor2  # pip install cbor2
except Exception:
    print("ERROR: python module 'cbor2' is required (pip install cbor2)", file=sys.stderr)
    sys.exit(2)
try:
    import blake3
except Exception:
    print("ERROR: python module 'blake3' is required (pip install blake3)", file=sys.stderr)
    sys.exit(2)

def main():
    if len(sys.argv) < 2:
        print("Usage: cbor_canon.py entry.json", file=sys.stderr)
        sys.exit(2)
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        entry = json.load(f)
    # Omit attestations
    if isinstance(entry, dict) and 'attestations' in entry:
        entry = {k:v for k,v in entry.items() if k != 'attestations'}
    # Canonical CBOR: cbor2.dumps(..., canonical=True)
    can = cbor2.dumps(entry, canonical=True)
    print(blake3.blake3(can).hexdigest())

if __name__ == '__main__':
    main()

