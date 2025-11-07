#!/usr/bin/env bash
# Reorder filelist:
#  1) float_metadata_pkg.sv -> last in packages block
#  2) SPEX128_top.sv        -> last line overall (top module)
# Usage:
#   ./fix_filelist_order.sh <filelist.f> [--dry-run]
#   ./fix_filelist_order.sh --top <basename.sv> <filelist.f> [--dry-run]

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 [--top TOP_BASENAME] <filelist.f> [--dry-run]
  --top       Basename of the top module file (default: SPEX128_top.sv)
  --dry-run   Show diff without modifying the file
EOF
}

TOP_NAME="SPEX128_top.sv"
DRY=0
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --top) TOP_NAME="${2:-}"; [[ -z "$TOP_NAME" ]] && { echo "--top needs a value" >&2; exit 2; }; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) FILE="${1}"; shift ;;
  esac
done

[[ -z "${FILE}" ]] && { usage; exit 2; }
[[ ! -f "${FILE}" ]] && { echo "No such file: ${FILE}" >&2; exit 2; }

# Escape for regex
escape_regex() { sed -e 's/[][\.^$*+?|(){}]/\\&/g'; }
TOP_ESC="$(printf '%s' "$TOP_NAME" | escape_regex)"

TMP="$(mktemp "${FILE}.XXXXXX")"

awk -v top_re="(^|/)"$TOP_ESC"([[:space:]]*)$" '
  # package detection & targets
  BEGIN {
    pkg_re  = "(^|/)packages/[^[:space:]]*\\.sv([[:space:]]*)$"
    meta_re = "(^|/)packages/float_metadata_pkg\\.sv([[:space:]]*)$"
    npre = np = nm = 0
    seen_any_file = 0
    meta = ""; top = ""
  }

  function is_pkg_line(s)  { return (s ~ pkg_re) }
  function is_meta_line(s) { return (s ~ meta_re) }
  function is_top_line(s)  { return (s ~ top_re) }

  {
    # First .sv or later content vs header
    if ($0 ~ /\.sv([[:space:]]*)$/) {
      seen_any_file = 1
      if (is_pkg_line($0)) {
        if (is_meta_line($0)) { meta = $0; next }
        pkgs[++np] = $0; next
      } else {
        if (is_top_line($0)) { top = $0; next }
        mods[++nm] = $0; next
      }
    } else {
      if (!seen_any_file) pre[++npre] = $0
      else                mods[++nm] = $0   # keep comments that appear after files start
    }
  }

  END {
    # Emit: header, packages (except meta), meta (if any), then everything else (except top), and finally top.
    for (i=1;i<=npre;i++) print pre[i]
    for (i=1;i<=np;i++)   print pkgs[i]
    if (meta != "")       print meta
    for (i=1;i<=nm;i++)   print mods[i]
    if (top != "")        print top
  }
' "$FILE" > "$TMP"

if [[ $DRY -eq 1 ]]; then
  echo "=== DRY RUN: diff ==="
  if command -v diff >/dev/null 2>&1; then
    diff -u --label="$FILE" --label="$FILE (reordered)" "$FILE" "$TMP" || true
  else
    cat "$TMP"
  fi
  rm -f "$TMP"
else
  mv "$TMP" "$FILE"
fi
