# Task: fix #152 — Continue replays first-time Story scenes and delays the chapter card

Read: `AGENTS.md`, `CONTEXT.md`, `docs/guides/testing.md`, `gh issue view 152` (if gh is denied, the text is below).

## Bug
Continue does not restore which Story presentations were already shown. `merchant_first` / `rest_first` replay later in the run.
The current Layer's chapter card is queued at Continue but stays hidden while Path Voting is pending (appears only after the vote).
Evidence: `src/client/story/story_director.gd:46-69` (clears `shown`; on restore marks only prologue, earlier chapter cards,
`first_combat_won`), `:95-114` (once-per-run scenes keyed by `shown`), `:145-148` (card deferred while a decision is pending unless
`opening_presentation_pending`, set only for a new Story at Layer 1), `src/match/match_run.gd:595-597` + `src/client/story/story_save.gd`
(save lacks presentation keys).

## Expected
- Continue at a saved Layer shows that Layer's chapter card BEFORE its first path choice.
- Previously seen first-time scenes stay seen after Continue. Persist the presentation state in the save (backwards-compatible: old saves
  without the field must still load and fall back to reconstruction from layer/progress) or reconstruct it. Prefer client-side
  `story_save.gd` persistence if it avoids changing the server save shape; otherwise keep `valid_story_save` strict but accept the new optional key.
- Client tests for both behaviours using a realistic restored voting snapshot (Layer 3, voting phase).

## Constraints
Minimal change, no other behaviour change. Do not touch `.claude`, `.ai/checkpoint.md`, assets, CI. Do not commit or push.
One Godot process at a time. `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`. No `git show ref:path` in this shell.

## Verify (paste exact lines)
Baseline `bash tools/run_tests.sh` before, then after: baseline + new, 0 failed, smoke passes; `--headless --path . --import` exit 0; `git status --short`.

## Report (under 150 words)
Root cause, approach (persist vs reconstruct), save-compat handling, tests, counts.
