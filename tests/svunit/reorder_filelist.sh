#!/usr/bin/env bash
# Reorder filelist:
#  1) Packages block order:
#       - all other packages
#       - float_metadata_pkg.sv(h)          (second-to-last in packages)
#       - binary128_convert_pkg.sv(h)       (last in packages)
#  2) <top>.sv -> last line overall (basename match)
#
# Usage:
#   ./reorder_filelist.sh [--top TOP_BASENAME] [<filelist.f>] [--dry-run]
# Defaults:
#   - TOP_BASENAME = SPEX128_top.sv
#   - filelist.f   = ./filelist.f (in CWD) if not provided

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 [--top TOP_BASENAME] [<filelist.f>] [--dry-run]
  --top       Basename of the top module file (default: SPEX128_top.sv)
  --dry-run   Show diff without modifying the file
If <filelist.f> is omitted, ./filelist.f is used.
EOF
}

TOP_NAME="SPEX128_top.sv"
DRY=0
FILE=""

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --top) TOP_NAME="${2:-}"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *)
      if [[ -z "$FILE" ]]; then FILE="$1"; shift; else echo "Unknown arg: $1" >&2; usage; exit 2; fi
      ;;
  esac
done

# default filelist if not provided
if [[ -z "$FILE" ]]; then
  FILE="./filelist.f"
fi
[[ -f "$FILE" ]] || { echo "No such file: ${FILE}" >&2; exit 2; }

TMP="$(mktemp "${FILE}.XXXXXX")"

# Do the reorder in one awk pass:
# - Files are those ending with .sv or .svh
# - Packages are paths containing /packages/
# - float_metadata_pkg.* is emitted right before convert_pkg block
# - binary128_convert_pkg.* is emitted as the last line of the packages block
# - Top is matched by BASENAME at end of the path (whitespace allowed after)
awk -v top_base="$TOP_NAME" '
  function is_file(s)     { return (s ~ /\.sv(h)?([[:space:]]*)$/) }
  function is_pkg(s)      { return (s ~ /\/packages\//) }
  function is_meta(s)     { return (s ~ /\/packages\/float_metadata_pkg\.sv(h)?([[:space:]]*)$/) }
  function is_convert(s)  { return (s ~ /\/packages\/binary128_convert_pkg\.sv(h)?([[:space:]]*)$/) }
  function is_top(s)      {
    gsub(/[[:space:]]+$/, "", s)
    n = split(s, parts, "/")
    return (parts[n] == top_base)
  }

  BEGIN {
    nh=0; np=0; nmeta=0; nconv=0; nm=0; nt=0; ntail=0
    files_seen=0
  }

  {
    if (is_file($0)) {
      files_seen=1
      if (is_pkg($0)) {
        if      (is_convert($0)) conv[++nconv] = $0
        else if (is_meta($0))    meta[++nmeta] = $0
        else                     pkgs[++np]    = $0
      } else {
        if (is_top($0))  top[++nt] = $0
        else             mods[++nm] = $0
      }
    } else {
      if (!files_seen) header[++nh] = $0
      else             tail[++ntail]= $0
    }
  }

  END {
    # header
    for (i=1;i<=nh;i++) print header[i]
    # packages (excluding meta & convert)
    for (i=1;i<=np;i++) print pkgs[i]
    # meta right before convert (if any)
    for (i=1;i<=nmeta;i++) print meta[i]
    # convert pkg LAST in packages block (if any)
    for (i=1;i<=nconv;i++) print conv[i]
    # non-package files (excluding top)
    for (i=1;i<=nm;i++) print mods[i]
    # any non-file lines that appeared after files started
    for (i=1;i<=ntail;i++) print tail[i]
    # top last overall (last occurrence wins)
    if (nt > 0) print top[nt]
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
