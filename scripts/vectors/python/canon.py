#!/usr/bin/env python3
import sys, json
try:
    import blake3  # pip install blake3
except Exception:
    blake3 = None

def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(2)

def canonical(obj):
    if isinstance(obj, dict):
        # sort keys by Unicode code point
        items = sorted(obj.items(), key=lambda kv: kv[0])
        return '{' + ','.join([f"{json.dumps(k, ensure_ascii=False)}:{canonical(v)}" for k,v in items]) + '}'
    elif isinstance(obj, list):
        return '[' + ','.join([canonical(x) for x in obj]) + ']'
    elif isinstance(obj, (int,)):
        return str(obj)
    elif isinstance(obj, float):
        die("floats are forbidden in canonical positions; encode as string")
    elif obj is None:
        return 'null'
    elif isinstance(obj, bool):
        return 'true' if obj else 'false'
    elif isinstance(obj, str):
        return json.dumps(obj, ensure_ascii=False)
    else:
        die(f"unsupported type: {type(obj)}")

def preimage(entry):
    # omit attestations for id preimage
    e = dict(entry)
    e.pop('attestations', None)
    return canonical(e)

def main():
    if len(sys.argv) < 2:
        print("Usage: canon.py entry.json", file=sys.stderr)
        sys.exit(2)
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    can_bytes = preimage(data).encode('utf-8')
    if blake3 is None:
        sys.stdout.write(can_bytes.decode('utf-8'))
        return
    h = blake3.blake3(can_bytes).hexdigest()
    print(h)

if __name__ == '__main__':
    main()

