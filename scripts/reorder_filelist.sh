#!/usr/bin/env bash
# Reorder filelist so float_metadata_pkg.sv is last in the packages section
# Usage: ./fix_filelist_order.sh path/to/filelist.f [--dry-run]

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <filelist.f> [--dry-run]" >&2
  exit 2
fi

FILE="$1"
DRY="${2-}"
[[ ! -f "$FILE" ]] && { echo "No such file: $FILE" >&2; exit 2; }

TMP="$(mktemp "${FILE}.XXXXXX")"

awk '
  function is_pkg_line(s) { return s ~ /(^|\/)packages\/.*\.sv[[:space:]]*$/ }
  function is_meta_line(s){ return s ~ /(^|\/)packages\/float_metadata_pkg\.sv[[:space:]]*$/ }

  BEGIN { seen_pkg = 0 }

  {
    if (is_pkg_line($0)) {
      seen_pkg = 1
      if (is_meta_line($0)) { meta = $0; next }
      pkgs[++np] = $0
      next
    }

    # Non-package line
    if (!seen_pkg) pre[++npre] = $0
    else           post[++npost] = $0
  }

  END {
    # If there were no package lines at all, or meta wasn’t present,
    # just reconstruct the original order.
    if (!seen_pkg || meta == "") {
      for (i=1;i<=npre;i++)  print pre[i]
      for (i=1;i<=np;i++)    print pkgs[i]
      for (i=1;i<=npost;i++) print post[i]
      exit 0
    }

    # Normal case: pre (header), then all pkgs (except meta), then meta, then post (modules/etc.)
    for (i=1;i<=npre;i++)  print pre[i]
    for (i=1;i<=np;i++)    print pkgs[i]
    print meta
    for (i=1;i<=npost;i++) print post[i]
  }
' "$FILE" > "$TMP"

if [[ "${DRY}" == "--dry-run" ]]; then
  echo "=== DRY RUN: diff ==="
  if command -v diff >/dev/null 2>&1; then
    diff -u --label="$FILE" --label="$FILE (reordered)" "$FILE" "$TMP" || true
  else
    echo "diff not found; showing new file:"
    cat "$TMP"
  fi
  rm -f "$TMP"
else
  mv "$TMP" "$FILE"
fi
