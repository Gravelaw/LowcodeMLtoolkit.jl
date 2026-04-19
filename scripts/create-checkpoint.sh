#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <checkpoint-tag>" >&2
  exit 1
fi

tag="$1"
notes_dir="docs/releases"
notes_file="${notes_dir}/${tag//\//-}.md"

mkdir -p "$notes_dir"

if [ ! -f "$notes_file" ]; then
  cat >"$notes_file" <<EOF
# ${tag}

## Summary

- Add summary here

## Evidence

- [ ] CI green
- [ ] ADR updated
- [ ] Schema versions reviewed
- [ ] Workflow fixture stored
- [ ] Rollback assets recorded
EOF
fi

git add "$notes_file"
git commit -m "Create release notes for ${tag}" >/dev/null 2>&1 || true
git tag -a "$tag" -m "Checkpoint ${tag}"
echo "created ${tag} with notes ${notes_file}"

