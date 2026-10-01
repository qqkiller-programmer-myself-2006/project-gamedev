# T44 — Finish issue #44 (keyboard + accessibility baseline)

Worktree branch `codex/accessibility-baseline-44` already has commit 6d885ac (not in main). Do:
1. `git fetch`, merge origin/main into the branch, resolve conflicts (main changed camp, battle, title a lot).
2. Read `gh issue view 44`. Check every acceptance criterion against the code and fix gaps: keyboard reachability of all primary actions on Battle/Merchant/Rest, visible predictable focus, item/status/action info without hover-only tooltips, reduced motion keeps state changes visible, 1.4x text hides no critical control.
3. Add/adjust tests under tests/client.
4. Capture evidence with `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t44 --seed=11 --speed=10` and `--scale=1.4` (check the actual script path in tools/).
Constraints: work only in this worktree; commit locally on this branch is OK; no push, no PR; never hand work to opencode.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass.
Final message: criteria checklist pass/fail, changed files, exact test summary line, screenshot paths.
