# Task: fix #151 — reject saves with an invalid route (Story Continue softlock)

Read: `AGENTS.md`, `CONTEXT.md`, `docs/guides/testing.md`, `gh issue view 151`.

## Bug
`src/match/match_run.gd:~602-608` validates only that `route` is an Array of the expected Layer count. A Layer that is `[]`
or a wrong type reaches `PathVote.new()` (`match_run.gd:~574-592`, Story deadline -1) -> zero options -> permanent Path Voting
softlock, or a runtime type error. `room.gd:~132-139` restores after that check.

## Do
1. Validate each Layer entry of `route` is an Array, non-empty, and every option is a Dictionary with the fields `PathVote`/route
   building actually requires (read `path_vote.gd` and how routes are generated to get the exact required keys and types).
   Do it in the existing save-validation step so it returns the existing `invalid_save` error and the client clears the broken save.
2. Regression tests (focused, in the existing restore test file or a new `tests/**/test_*.gd` next to it): empty current Layer,
   wrong-type Layer, wrong-type option, and a valid save still restores. Keep `.uid` files with new scripts.
3. No other behaviour change. Do not touch `.claude`, `.ai/checkpoint.md`, assets, CI. Do not commit or push.
   One Godot process at a time. `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`.
   No `git show ref:path` in this shell.

## Verify (paste exact lines)
- Baseline `bash tools/run_tests.sh` BEFORE changes, then after: baseline + new, 0 failed, smoke scripts pass.
- `"$GODOT" --headless --path . --import` exits 0.
- `git status --short`.

## Report (under 150 words)
Root cause confirmed, fields validated, tests added, counts before/after.
