#!/usr/bin/env bash
# setup_svunit.sh — source this from the project root

# Detect if this file is being sourced
_is_sourced=0
[[ "${BASH_SOURCE[0]}" != "$0" ]] && _is_sourced=1

# Resolve project root from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SVUNIT_DIR="$SCRIPT_DIR/tools/svunit"

if [ ! -d "$SVUNIT_DIR" ]; then
  echo "Error: tools/svunit directory not found relative to script."
  if [ $_is_sourced -eq 1 ]; then return 1; else exit 1; fi
fi

echo "Setting up environment variables..."

# Export expected vars before sourcing
export SVUNIT_INSTALL="$SVUNIT_DIR"

# Add bin once
case ":$PATH:" in
  *":$SVUNIT_INSTALL/bin:"*) ;;
  *) export PATH="$PATH:$SVUNIT_INSTALL/bin" ;;
esac

# Source in the svunit directory so any `pwd` in Setup.bsh matches tools/svunit
pushd "$SVUNIT_INSTALL" >/dev/null || { echo "pushd failed"; if [ $_is_sourced -eq 1 ]; then return 1; else exit 1; fi; }
# shellcheck source=/dev/null
source "./Setup.bsh"
popd >/dev/null

# echo "SVUNIT_INSTALL=$SVUNIT_INSTALL"

echo "Setting up tests/svunit/filelist.f..."
./scripts/gen_filelist.sh
./scripts/reorder_filelist.sh tests/svunit/filelist.f

echo "Done"
