#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# gen_svunit_waves.sh
# Produce a ModelSim/Questa WLF from an SVUnit build directory.
#
# Defaults assume you're running from an SVUnit test dir that already has:
#   - ./work/ (compiled library)
#   - compile.log (so we can detect the top)
# -----------------------------------------------------------------------------

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  -t <top>       Top module name (default: auto-detect from compile.log, else 'testrunner')
  -s <scope>     Hierarchy to log (Tcl regexp). Default: '/*' (everything)
                 Example: '/exp_functionality_unit_test/*'
  -o <wlf>       Output WLF path. Default: ./waves/svunit.wlf
  -m <ini>       modelsim.ini path to create/use. Default: ./modelsim.ini
  -w <workdir>   Work library directory. Default: ./work
  -g             Open the WLF in GUI after generation
  -h             Show this help

Examples:
  $0 -s '/exp_functionality_unit_test/*'
  $0 -t testrunner -o ./waves/run1.wlf
USAGE
}

TOP=""
SCOPE='/*'
WLF_OUT="./waves/svunit.wlf"
MSI="./modelsim.ini"
WORKDIR="./work"
OPEN_GUI=0

while getopts ":t:s:o:m:w:gh" opt; do
  case "$opt" in
    t) TOP="$OPTARG" ;;
    s) SCOPE="$OPTARG" ;;
    o) WLF_OUT="$OPTARG" ;;
    m) MSI="$OPTARG" ;;
    w) WORKDIR="$OPTARG" ;;
    g) OPEN_GUI=1 ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option -$OPTARG"; usage; exit 2 ;;
    :)  echo "Option -$OPTARG requires an argument"; usage; exit 2 ;;
  esac
done

# --- Preconditions ------------------------------------------------------------
command -v vsim >/dev/null || { echo "vsim not found in PATH"; exit 1; }
command -v vmap >/dev/null || { echo "vmap not found in PATH"; exit 1; }
command -v vdir >/dev/null || { echo "vdir not found in PATH"; exit 1; }

[ -d "$WORKDIR" ] || { echo "Work library dir not found: $WORKDIR"; exit 1; }
[ -f "$WORKDIR/_info" ] || { echo "Not a valid ModelSim library: $WORKDIR"; exit 1; }

# --- Detect top if not provided ----------------------------------------------
if [ -z "$TOP" ]; then
  if [ -f compile.log ]; then
    # Find "Top level modules:" then read the next non-empty token on the next lines
    TOP_CAND=$(awk '
      $0 ~ /Top level modules:/ {flag=1; next}
      flag && NF {print $1; exit}
    ' compile.log || true)
    if [ -n "$TOP_CAND" ]; then
      TOP="$TOP_CAND"
    else
      TOP="testrunner"
    fi
  else
    TOP="testrunner"
  fi
fi

# --- Prepare output dir -------------------------------------------------------
mkdir -p "$(dirname "$WLF_OUT")"

# --- Create a minimal modelsim.ini mapping (absolute path) -------------------
ABS_WORKDIR="$(cd "$WORKDIR" && pwd -P)"
cat > "$MSI" <<EOF
[Library]
work = $ABS_WORKDIR
others = \$MODEL_TECH/../modelsim.ini
EOF

# Sanity check
vmap -modelsimini "$MSI" >/dev/null

# Optional: list units (useful for debugging; comment out if noisy)
# vsim -c -modelsimini "$MSI" -do "vdir work; quit -f"

# --- Run simulation headless and dump WLF ------------------------------------
DO_SCRIPT=$(mktemp)
cat > "$DO_SCRIPT" <<EOF
log -r $SCOPE
run -all
quit -f
EOF

vsim -c -modelsimini "$MSI" \
     -wlf "$WLF_OUT" "work.$TOP" \
     -do "$DO_SCRIPT"

rm -f "$DO_SCRIPT"

echo "WLF written to: $WLF_OUT"

# --- Optional: open GUI viewer -----------------------------------------------
if [ "$OPEN_GUI" -eq 1 ]; then
  vsim -view "$WLF_OUT" &
fi
