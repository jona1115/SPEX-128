#!/usr/bin/env bash

# Vibe coded to mask verilator junk outputs

# SVUnit wrapper:
# - Default: concise human-readable summary (tests, suites, Verilator report)
# - -v/--verbose: full raw log
# - --ci or GITHUB_ACTIONS=true: ultra-clean CI output + GitHub annotations + step summary
# - On build error (non-zero exit or '%Error:'), always prints full raw log
# - Always saves the full raw log to ./run.log

set -u -o pipefail

usage() {
  cat <<'EOF'
Usage: $0 [-v|--verbose] [--ci] [-s|--simulator <questa|verilator|vcs|...] [-h|--help]
Runs:  runSVUnit -s verilator -f ../filelist.f

Behavior:
- Default: concise summary (tests + suites + Verilator report)
- -v/--verbose: print full raw output
- --ci or GITHUB_ACTIONS=true: one-line summary + failing tests only + GH annotations + step summary
- On build error (non-zero exit or '%Error:'), prints full raw log
- Writes full raw log to ./run.log

Exit code:
- Mirrors runSVUnit unless tests fail; then returns 1 even if runSVUnit returned 0.
EOF
}

VERBOSE=0
CI_MODE=0

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=1; shift ;;
    --ci) CI_MODE=1; shift ;;
    -s|--simulator)
      if (( $# >= 2 )) && [[ ${2} != -* ]]; then
        SIMULATOR="$2"; shift 2
      else
        echo "Error: -s|--simulator requires an argument"; usage; exit 2
      fi
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
  esac
done

# Auto-enable CI mode in GitHub Actions
if [[ ${GITHUB_ACTIONS:-} == "true" ]]; then
  CI_MODE=1
fi

# Command to run (as requested)
CMD=(runSVUnit -s "$SIMULATOR" -f ../filelist.f)

# Print the running command BEFORE doing anything
echo "Running: ${CMD[*]}"

# temp file for captured output
LOG="$(mktemp -t svunit_run_XXXXXX.log)"
trap 'rm -f "$LOG"' EXIT

# Run and capture (no -e so we can inspect exit code)
# We capture to $LOG first, then copy to ./run.log for artifacts
"${CMD[@]}" >"$LOG" 2>&1
rc=$?
cp -f "$LOG" ./run.log || true

# If verbose OR build error patterns OR non-zero exit, dump full output and exit
if [[ $VERBOSE -eq 1 ]] || [[ $rc -ne 0 ]] || grep -qE '^\%Error:' "$LOG"; then
  cat "$LOG"
  exit $rc
fi

# ---------- Parse ----------
# 1) Overall testrunner summary line
testrunner_line="$(grep -E '\[testrunner\]: (PASSED|FAILED) \([^)]+\)' "$LOG" | tail -1 | sed 's/^INFO:\s*//')"

# 2) Per-test results "<unit>.<test>"
extract_tests() {
  local status="$1"   # PASSED or FAILED
  grep -E "::${status}[[:space:]]*$" "$LOG" \
    | sed -E 's/^.*\[[0-9]+\]\[([^]]+)\]:[[:space:]]*([^:]+)::(PASSED|FAILED).*$/\1.\2/' \
    | sed '/^[[:space:]]*$/d'
}
passed_tests="$(extract_tests PASSED)"
failed_tests="$(extract_tests FAILED)"

pass_count=0
fail_count=0
[[ -n "$passed_tests" ]] && pass_count=$(printf "%s\n" "$passed_tests" | wc -l | tr -d ' ')
[[ -n "$failed_tests" ]] && fail_count=$(printf "%s\n" "$failed_tests" | wc -l | tr -d ' ')
total=$(( pass_count + fail_count ))

# 3) Per-suite summaries and counts
suite_summaries="$(grep -E '\]: (PASSED|FAILED) \([0-9]+ of [0-9]+ (tests|testcases) passing\)' "$LOG" \
                   | sed 's/^INFO:\s*//')"
total_suites=0
suites_passed=0
if [[ -n "$suite_summaries" ]]; then
  total_suites=$(printf '%s\n' "$suite_summaries" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
  suites_passed=$(printf '%s\n' "$suite_summaries" | grep -c ' PASSED ' || true)
fi

# 4) Verilator report lines (compile/sim reports, walltime/cpu/mem)
verilator_report="$(grep -E '^- (Verilator:|S i m u l a t i o n|V e r i l a t i o n)' "$LOG" || true)"

# Determine status from testrunner
status="UNKNOWN"
if echo "$testrunner_line" | grep -q "PASSED"; then status="PASSED"; fi
if echo "$testrunner_line" | grep -q "FAILED"; then status="FAILED"; fi

# ---------- Output ----------
if [[ $CI_MODE -eq 1 && $VERBOSE -eq 0 ]]; then
  # CI mode: single summary + failures + annotations + step summary
  echo "SVUnit: ${pass_count}/${total} tests passed; ${suites_passed}/${total_suites} suites passed; status=${status}"

  if [[ $fail_count -gt 0 ]]; then
    echo "Failing tests:"
    # shellcheck disable=SC2086
    printf '  - %s\n' $failed_tests
  fi

  # GitHub Annotations for Verilator compile errors (if any slipped through)
  while IFS= read -r line; do
    if [[ "$line" =~ ^%Error:\ ([^:]+):([0-9]+):([0-9]+):\ (.*)$ ]]; then
      f="${BASH_REMATCH[1]}"; l="${BASH_REMATCH[2]}"; c="${BASH_REMATCH[3]}"; msg="${BASH_REMATCH[4]}"
      echo "::error file=$f,line=$l,col=$c::$msg"
    elif [[ "$line" =~ ^%Error:\ ([^:]+):([0-9]+):\ (.*)$ ]]; then
      f="${BASH_REMATCH[1]}"; l="${BASH_REMATCH[2]}"; msg="${BASH_REMATCH[3]}"
      echo "::error file=$f,line=$l::$msg"
    fi
  done < <(grep -E '^\%Error:' "$LOG" || true)

  # GitHub Annotations for failed tests (no file context, but still helpful)
  if [[ $fail_count -gt 0 ]]; then
    # shellcheck disable=SC2086
    for t in $failed_tests; do
      echo "::error title=SVUnit test failed::$t"
    done
  fi

  # GitHub Step Summary (Markdown)
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "### SVUnit Summary"
      echo
      echo "- **Status:** $status"
      echo "- **Tests:** $pass_count / $total passed"
      echo "- **Suites:** $suites_passed / $total_suites passed"
      echo
      if [[ $fail_count -gt 0 ]]; then
        echo "**Failing tests**:"
        # shellcheck disable=SC2086
        printf -- "- %s\n" $failed_tests
        echo
      fi
      if [[ -n "$verilator_report" ]]; then
        echo "<details><summary>Verilator report</summary>"
        echo
        printf '```\n%s\n```\n' "$verilator_report"
        echo "</details>"
      fi
      echo
      echo "<sub>Full raw log saved to <code>run.log</code>.</sub>"
    } >> "$GITHUB_STEP_SUMMARY"
  fi
else
  # Human-friendly concise summary
  echo "===== SVUnit Summary ====="
  if [[ -n "$testrunner_line" ]]; then
    echo "$testrunner_line"
  else
    echo "testrunner summary: (not found)"
  fi

  echo
  echo "Tests: ${pass_count}/${total} passed"
  if [[ $pass_count -gt 0 ]]; then
    echo "  Passed:"
    # shellcheck disable=SC2086
    printf '    - %s\n' $passed_tests
  fi
  if [[ $fail_count -gt 0 ]]; then
    echo "  Failed:"
    # shellcheck disable=SC2086
    printf '    - %s\n' $failed_tests
  fi

  if [[ -n "$suite_summaries" ]]; then
    echo
    echo "Suites:"
    printf '%s\n' "$suite_summaries"
  fi

  if [[ -n "$verilator_report" ]]; then
    echo
    echo "Verilator report:"
    printf '%s\n' "$verilator_report"
  fi

  echo
  echo "(Full raw log saved to ./run.log)"
fi

# Make CI/dev-friendly: if tests failed, return non-zero even if runSVUnit returned 0.
if [[ $rc -eq 0 ]] && { [[ $status == "FAILED" ]] || [[ $fail_count -gt 0 ]]; }; then
  rc=1
fi

exit $rc
