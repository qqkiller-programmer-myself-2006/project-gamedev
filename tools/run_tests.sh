#!/usr/bin/env bash
# Runs the headless GDScript test suite, then the standalone layout smoke scripts.
#   ./tools/run_tests.sh                 # unit suite + layout smoke scripts
#   ./tools/run_tests.sh --filter=voting # only tests whose id contains "voting" (smoke scripts skipped)
# Smoke scripts are every tests/client/*.gd that does not start with test_ (the runner discovers
# test_*.gd itself). Each is a SceneTree script that exits non-zero on failure.
# Set GODOT to the Godot 4.7 binary if it is not on PATH as `godot`.
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
# Build the class_name cache (.godot/) so global classes resolve.
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

status=0
"$GODOT" --headless --path . -s tests/run_tests.gd -- "$@" < /dev/null || status=$?

# A --filter run is a focused unit run; the smoke scripts only run for the full suite.
if [ "$#" -eq 0 ]; then
	failed=()
	for script in tests/client/*.gd; do
		name="$(basename "$script" .gd)"
		case "$name" in test_*) continue ;; esac
		echo "== smoke: $name"
		if ! "$GODOT" --headless --path . -s "$script" < /dev/null; then
			failed+=("$name")
		fi
	done
	if [ "${#failed[@]}" -gt 0 ]; then
		echo "SMOKE FAILED: ${failed[*]}"
		status=1
	fi
fi
exit "$status"
