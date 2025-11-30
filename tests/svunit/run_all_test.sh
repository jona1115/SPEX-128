#!/usr/bin/env bash
# Run all SVUnit module suites from tests/svunit, stream outputs, and summarize totals.
#
# Usage:
#   ./run_all_test.sh [options]
#
# Options:
#   -s, --simulator <questa|modelsim|verilator|vcs|...>
#   --only <module>            Run only this module (repeatable)
#   --exclude <module>         Skip this module (repeatable)
#   --list                     List detected modules and exit
#   -h, --help                 Show help
#
# Behavior:
# - Detects module test folders as immediate subdirs containing *_unit_test.sv
# - For every module, invokes: ../svunit_run.sh --ci --all [-s <sim>]
# - Streams output to console and saves full log to <module>/regression.log
# - Parses "SVUnit: X/Y tests passed; A/B suites passed; status=PASSED|FAILED"
# - Prints consolidated summary with totals, then exits 1 if any module failed

set -euo pipefail

usage() { sed -n '2,32p' "$0"; }

SIMULATOR=""
LIST_ONLY=0
declare -a ONLY=()
declare -a EXCLUDE=()

# ---------- args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--simulator)
      (( $# >= 2 )) && [[ $2 != -* ]] || { echo "Missing simulator for $1" >&2; exit 2; }
      SIMULATOR="$2"; shift 2 ;;
    --only)
      (( $# >= 2 )) && [[ $2 != -* ]] || { echo "Missing module for --only" >&2; exit 2; }
      ONLY+=("$2"); shift 2 ;;
    --exclude)
      (( $# >= 2 )) && [[ $2 != -* ]] || { echo "Missing module for --exclude" >&2; exit 2; }
      EXCLUDE+=("$2"); shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# ---------- location ----------
THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
cd "$THIS_DIR"

# ---------- discover ----------
discover_modules() {
  for d in */ ; do
    [[ -d "$d" ]] || continue
    mod="${d%/}"
    if find "$mod" -type f -name '*_unit_test.sv' | grep -q . ; then
      echo "$mod"
    fi
  done | LC_ALL=C sort
}

in_list() { local x="$1"; shift; for y in "$@"; do [[ "$x" == "$y" ]] && return 0; done; return 1; }

modules=($(discover_modules))

# ONLY filter
if ((${#ONLY[@]})); then
  filtered=()
  for m in "${modules[@]}"; do in_list "$m" "${ONLY[@]}" && filtered+=("$m"); done
  modules=("${filtered[@]}")
fi

# EXCLUDE filter
if ((${#EXCLUDE[@]})); then
  filtered=()
  for m in "${modules[@]}"; do in_list "$m" "${EXCLUDE[@]}" || filtered+=("$m"); done
  modules=("${filtered[@]}")
fi

if (( LIST_ONLY )); then
  printf '%s\n' "${modules[@]}"
  exit 0
fi

((${#modules[@]})) || { echo "No SVUnit modules discovered under $(pwd -P)" >&2; exit 2; }

echo "Found ${#modules[@]} module(s): ${modules[*]}"

# ---------- run & collect ----------
declare -a report_mod=()
declare -a report_status=()
declare -a report_tests=()    # "passed/total"
declare -a report_suites=()   # "passed/total"
declare -i total_pass=0 total_count=0 failures=0

for mod in "${modules[@]}"; do
  echo
  echo "===== Running: ${mod} ====="
  pushd "$mod" >/dev/null

  # Build command: always --ci and --all
  cmd=(../svunit_run.sh --ci --all)
  [[ -n "$SIMULATOR" ]] && cmd+=(-s "$SIMULATOR")

  echo "CMD: ${cmd[*]}"

  # Run and stream output; keep going even if it fails
  set +e
  { "${cmd[@]}" 2>&1 | tee regression.log ; } 
  rc=${PIPESTATUS[0]}
  set -e

  # Parse the CI summary line
  line="$(grep -m1 '^SVUnit:' regression.log || true)"
  status="UNKNOWN"; tests="0/0"; suites="0/0"
  if [[ -n "$line" ]]; then
    re='^SVUnit: ([0-9]+)/([0-9]+) tests passed; ([0-9]+)/([0-9]+) suites passed; status=([A-Z]+)'
    if [[ $line =~ $re ]]; then
      tp="${BASH_REMATCH[1]}"; tt="${BASH_REMATCH[2]}"
      sp="${BASH_REMATCH[3]}"; st="${BASH_REMATCH[4]}"
      status="${BASH_REMATCH[5]}"
      tests="${tp}/${tt}"
      suites="${sp}/${st}"
      total_pass=$(( total_pass + tp ))
      total_count=$(( total_count + tt ))
    fi
  fi

  # Count failures by status or non-zero exit
  [[ "$status" == "FAILED" || $rc -ne 0 ]] && failures=$((failures + 1))

  report_mod+=("$mod")
  report_status+=("$status")
  report_tests+=("$tests")
  report_suites+=("$suites")

  popd >/dev/null
done

# ---------- summary ----------
echo
echo "================ Regression Summary ================"
printf "%-28s %-10s %-14s %-14s\n" "Module" "Status" "Tests(p/T)" "Suites(p/T)"
printf "%-28s %-10s %-14s %-14s\n" "------" "------" "-----------" "------------"

for i in "${!report_mod[@]}"; do
  m="${report_mod[$i]}"; s="${report_status[$i]}"; t="${report_tests[$i]}"; u="${report_suites[$i]}"
  printf "%-28s %-10s %-14s %-14s\n" "$m" "$s" "$t" "$u"
done

echo "---------------------------------------------------"
echo "Total tests run: ${total_count}"
echo "Total tests passed: ${total_pass}"
echo "Failures: ${failures} module(s)"

# GitHub Step Summary (optional)
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### SVUnit Regression Summary"
    echo
    echo "| Module | Status | Tests (p/T) | Suites (p/T) |"
    echo "|:------ |:------:|:-----------:|:------------:|"
    for i in "${!report_mod[@]}"; do
      echo "| ${report_mod[$i]} | ${report_status[$i]} | ${report_tests[$i]} | ${report_suites[$i]} |"
    done
    echo
    echo "**Totals:** ${total_pass}/${total_count} tests passed. Failures: ${failures} module(s)."
    echo
    echo "_Per-module logs saved to \`<module>/regression.log\`._"
  } >> "$GITHUB_STEP_SUMMARY"
fi

# Exit non-zero if any module failed
exit $(( failures > 0 ? 1 : 0 ))
