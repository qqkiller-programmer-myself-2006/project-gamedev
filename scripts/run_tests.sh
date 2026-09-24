#!/usr/bin/env bash
# Runs the headless GDScript test suite.
#   ./scripts/run_tests.sh                 # every test
#   ./scripts/run_tests.sh --filter=voting # only tests whose id contains "voting"
# Set GODOT to the Godot 4.7 binary if it is not on PATH as `godot`.
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
# Build the class_name cache (.godot/) so global classes resolve.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
exec "$GODOT" --headless --path . -s tests/run_tests.gd -- "$@" < /dev/null
