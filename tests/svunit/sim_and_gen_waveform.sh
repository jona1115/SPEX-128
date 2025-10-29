#!/usr/bin/env bash
# sim_and_gen_waveform.sh — clean → run SVUnit → generate wave
# Works when sourced or executed from a test directory:
#   source ../sim_and_gen_waveform.sh [svunit_run flags...]
#   ../sim_and_gen_waveform.sh         [svunit_run flags...]

set -euo pipefail

# Detect if sourced (so 'return' won't kill your shell)
_is_sourced=0
[[ "${BASH_SOURCE[0]}" != "$0" ]] && _is_sourced=1

usage() {
  cat <<'EOF'
Usage: source sim_and_gen_waveform.sh [OPTIONS for svunit_run.sh]

What does it do:
  1) clean.sh
  2) svunit_run.sh [forwarded options]
  3) <proj-root>/scripts/generate_modelsim_wave.sh

Common options (forwarded to svunit_run.sh):
  -v, --verbose
  --ci
  -s, --simulator <questa|modelsim|verilator|...>
    (If not provided, defaults to "-s modelsim")

Help:
  -h, --help        Show this help and exit.
EOF
}

# Early help handling
for a in "$@"; do
  case "$a" in
    -h|--help)
      usage
      if (( _is_sourced )); then return 0; else exit 0; fi
      ;;
  esac
done

die() {
  echo "Error: $*" >&2
  if (( _is_sourced )); then return 1; else exit 1; fi
}

# Resolve paths:
#   SCRIPT_DIR = <proj>/tests/svunit
#   PRJ_ROOT   = <proj>
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PRJ_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"

CLEAN_SH="$SCRIPT_DIR/clean.sh"
SVUNIT_SH="$SCRIPT_DIR/svunit_run.sh"
GEN_WAVE_SH="$PRJ_ROOT/scripts/generate_modelsim_wave.sh"

[[ -x "$SVUNIT_SH" ]] || die "svunit_run.sh not found or not executable at: $SVUNIT_SH"
[[ -x "$GEN_WAVE_SH" ]] || die "generate_modelsim_wave.sh not found or not executable at: $GEN_WAVE_SH"
[[ -x "$CLEAN_SH" ]] || echo "Warning: clean.sh not found at $CLEAN_SH (continuing)."

# Target waveform file (relative to the test dir you run from)
WLF_PATH="./waves/svunit.wlf"
WLF_TIMEOUT_SEC=60          # max wait for WLF to exist
WLF_STABLE_WINDOW_SEC=1     # size must be unchanged for this duration

filesize() {
  local f=$1
  if stat -c%s "$f" >/dev/null 2>&1; then
    stat -c%s "$f"
  else
    stat -f%z "$f"
  fi
}

wait_for_wlf_stable() {
  local f="$1" timeout="$2" stable_window="$3"
  local start_t now_t
  start_t=$(date +%s)

  # Wait for file to appear
  while [[ ! -f "$f" ]]; do
    now_t=$(date +%s)
    (( now_t - start_t >= timeout )) && return 1
    sleep 0.2
  done

  # Wait for size to stabilize
  local last_sz=-1 stable_start_t=
  while :; do
    local cur_sz
    cur_sz=$(filesize "$f" 2>/dev/null || echo -1)
    now_t=$(date +%s)

    if [[ "$cur_sz" == "$last_sz" && "$cur_sz" -ge 0 ]]; then
      [[ -z "$stable_start_t" ]] && stable_start_t="$now_t"
      (( now_t - stable_start_t >= stable_window )) && return 0
    else
      stable_start_t=""
      last_sz="$cur_sz"
    fi

    (( now_t - start_t >= timeout )) && return 2
    sleep 0.2
  done
}

# Build the args to forward to svunit_run.sh (do NOT forward -h/--help)
SVARGS=()
for a in "$@"; do
  case "$a" in -h|--help) ;; * ) SVARGS+=("$a") ;; esac
done

# Ensure a default simulator if none provided
has_sim=0
for ((i=0; i<${#SVARGS[@]}; i++)); do
  if [[ "${SVARGS[i]}" == "-s" || "${SVARGS[i]}" == "--simulator" ]]; then
    has_sim=1; break
  fi
done
if (( !has_sim )); then
  SVARGS=(-s modelsim "${SVARGS[@]}")
fi

echo "==> Clean (optional)"
if [[ -x "$CLEAN_SH" ]]; then
  "$CLEAN_SH" || die "clean.sh failed"
fi

echo "==> Run SVUnit: ${SVARGS[*]}"
SVUNIT_STATUS=0
if ! "$SVUNIT_SH" "${SVARGS[@]}"; then
  SVUNIT_STATUS=$?
  echo "SVUnit exited with ${SVUNIT_STATUS}. Continuing to wave generation."
fi

echo "==> Generate ModelSim wave artifacts"
"$GEN_WAVE_SH" || die "generate_modelsim_wave.sh failed"

# echo "==> Waiting for WLF to be ready: $WLF_PATH"
# if ! wait_for_wlf_stable "$WLF_PATH" "$WLF_TIMEOUT_SEC" "$WLF_STABLE_WINDOW_SEC"; then
#   echo "WLF not stable within timeout (${WLF_TIMEOUT_SEC}s). Attempting to open anyway."
# fi

command -v vsim >/dev/null 2>&1 || die "vsim not found in PATH"
if [[ -z "${DISPLAY:-}" ]]; then
  echo "Warning: \$DISPLAY is not set; vsim GUI may fail."
fi

# echo "==> Opening ModelSim waveform"
# sleep 2 # I (jonathan) have no idea why you need to wait
# echo "==> Note: If modelsim fail to open, run: vsim -view ./waves/svunit.wlf"
echo "==> Next step, to view waveform, run: vsim -view ./waves/svunit.wlf"
# # Launch in background; 'disown' avoids job-control messages if sourced
# vsim -view "$WLF_PATH" & disown || true

# Return overall status = SVUnit's status (viewer already launched)
if (( _is_sourced )); then
  return "$SVUNIT_STATUS"
else
  exit "$SVUNIT_STATUS"
fi
