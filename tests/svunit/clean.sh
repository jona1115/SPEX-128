#!/usr/bin/env bash
# safe_clean.sh — remove generated files, but never '.' or '..'
# Prints each top-level path as it's removed.

set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: safe_clean.sh [--dry-run|-n]

Removes:
  .[!.]*  ..?*  *.log  *.xml  wave*  modelsim.ini  work  obj_dir
but never '.' or '..'. Prints each top-level item it removes.
USAGE
}

# Parse args
dry_run=0
if [[ "${1:-}" =~ ^(-n|--dry-run|--help|-h)$ ]]; then
  if [[ "$1" == "-n" || "$1" == "--dry-run" ]]; then
    dry_run=1
  else
    usage; exit 0
  fi
fi

# Patterns you wanted, with safe dot-globs to exclude '.' and '..'
patterns=(
  '.[!.]*'      # dotfiles/dirs except '.'
  '..?*'        # dotfiles/dirs starting with '..' but not exactly '..'
  '*.log'
  '*.xml'
  'wave*'
  'modelsim.ini'
  'work'
  'obj_dir'
  'transcript'
)

# Collect unique matches safely (globs that don't match yield nothing)
declare -a matches=()
declare -A seen=()
for pat in "${patterns[@]}"; do
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    [[ "$path" == "." || "$path" == ".." ]] && continue
    # De-dup
    if [[ -z "${seen[$path]:-}" ]]; then
      matches+=("$path")
      seen["$path"]=1
    fi
  done < <(compgen -G "$pat" || true)
done

if (( ${#matches[@]} == 0 )); then
  echo "Nothing to remove."
  exit 0
fi

if (( dry_run )); then
  echo "Dry run — would remove ${#matches[@]} item(s):"
  for p in "${matches[@]}"; do printf '  %q\n' "$p"; done
  exit 0
fi

echo "Removing ${#matches[@]} item(s):"
for p in "${matches[@]}"; do
  printf '  %q\n' "$p"
done

# Remove one by one so we print exactly what we remove (top-level)
for p in "${matches[@]}"; do
  # Print action, then remove
  printf 'rm -rf -- %q\n' "$p"
  rm -rf -- "$p"
done

echo "Done."
