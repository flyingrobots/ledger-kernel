#!/usr/bin/env bash
set -euo pipefail

root_dir=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p "$root_dir/docs/spec" \
         "$root_dir/docs/model" \
         "$root_dir/docs/reference" \
         "$root_dir/docs/architecture" \
         "$root_dir/docs/compliance" \
         "$root_dir/docs/implementation"

# Copy source-of-truth root docs into VitePress section index pages
cp -f "$root_dir/SPEC.md"           "$root_dir/docs/spec/index.md"
cp -f "$root_dir/MODEL.md"          "$root_dir/docs/model/index.md"
cp -f "$root_dir/REFERENCE.md"      "$root_dir/docs/reference/index.md"
cp -f "$root_dir/ARCHITECTURE.md"   "$root_dir/docs/architecture/index.md"
cp -f "$root_dir/COMPLIANCE.md"     "$root_dir/docs/compliance/index.md"

# Optional: include implementation paper/details if present
if [ -f "$root_dir/IMPLEMENTATION.md" ]; then
  cp -f "$root_dir/IMPLEMENTATION.md" "$root_dir/docs/implementation/index.md"
fi

echo "Synced core docs into docs/ sections."

