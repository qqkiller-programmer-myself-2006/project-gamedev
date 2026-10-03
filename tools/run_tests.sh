#!/usr/bin/env bash
# Runs the headless GDScript test suite, then the standalone layout smoke scripts.
#   ./tools/run_tests.sh                 # unit suite + layout smoke scripts
#   ./tools/run_tests.sh --filter=voting # only tests whose id contains "voting" (smoke scripts skipped)
# Smoke scripts are every tests/client/*.gd that does not start with test_ (the runner discovers
# test_*.gd itself). Each is a SceneTree script that exits non-zero on failure.
# Set GODOT to the Godot 4.7 binary if it is not on PATH as `godot`.
# When GODOT is a path (local machine), at most GODOT_TEST_SLOTS (default 2) suites run at once
# across all worktrees, because parallel Godot runs ran out of RAM and failed silently (exit 127).
# Slots are directories next to the Godot binary; a slot older than 45 minutes counts as stale.
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

slot_dir=""
release_slot() { [ -n "$slot_dir" ] && rm -rf "$slot_dir"; }
case "$GODOT" in
	*/*|*\\*)
		slots_root="$(dirname "$GODOT")/.test-slots"
		mkdir -p "$slots_root" 2>/dev/null || true
		max_slots="${GODOT_TEST_SLOTS:-2}"
		waited=0
		while [ -z "$slot_dir" ]; do
			for i in $(seq 1 "$max_slots"); do
				candidate="$slots_root/slot$i"
				if mkdir "$candidate" 2>/dev/null; then
					echo "$(date +%s) $PWD" > "$candidate/owner"
					slot_dir="$candidate"
					trap release_slot EXIT
					break
				fi
				# No owner file yet means another run is mid-acquire: leave it alone.
				if [ -f "$candidate/owner" ]; then
					started="$(cut -d' ' -f1 "$candidate/owner" 2>/dev/null)"
					if [ $(( $(date +%s) - ${started:-$(date +%s)} )) -gt 2700 ]; then
						rm -rf "$candidate"
					fi
				fi
			done
			if [ -z "$slot_dir" ]; then
				[ "$waited" -eq 0 ] && echo "Waiting for a free Godot test slot ($slots_root)..."
				waited=1
				sleep 10
			fi
		done
		;;
esac
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
