# Task: make `tools/dev/story_preview.gd --full` pass again

Symptom (reproduced on current `main`, before any recent UI work too): running

    "D:/dev-tools/godot/Godot_v4.7.2-stable_win64.exe" --path . --rendering-driver opengl3 -s tools/dev/story_preview.gd -- --out=build/shots/full --full

saves `01_home_play`, `02_class_pick`, `03_prologue_match`, `04_chapter_card` and then prints
`story_preview: first combat never reached a visible human action window` and exits 1; `05_story_battle.png` is never written.
(The non-console exe opens a real window, which is needed for screenshots. A headless run only writes blank images.)

The wait loop is in `_full_preview()` (after `app.send({"type": "vote", "option": combat_option})`): it waits up to 900 frames for
phase encounter/boss + `encounter.kind == "combat"` + `your_turn` + `match_screen._battle_mode` + battle view visible + no Story overlay.

## Do (systematic debugging first, then fix)
1. **Diagnose the root cause** — do not just raise the frame limit. Print what the loop sees each ~60 frames (phase, encounter kind,
   your_turn, `_battle_mode`, battle visibility, `_story_director.current`, `snapshot.match.vote`, room/ready state) in a throwaway
   debug run. Likely candidates: the vote needs the other 4 AI travellers/Ready before it resolves (path vote changed in T34/T42:
   Ready bar, vote summary); the vote may resolve to a non-combat route; Story overlay (chapter card / dialogue) blocks; `your_turn`
   needs the player to act first; the match clock/speed in offline Story mode (`start_story(..., {}, 1000)`).
2. **Decide where the bug is.** If the preview is just stale against the current flow (e.g. needs to ready/confirm the vote, advance
   a Story overlay, press a key), fix the preview script. If it reveals a real game bug (the combat never starts in Story mode),
   STOP and report it with evidence instead of papering over it in the preview — do not change game code without saying so in the report.
3. Keep the script's purpose: it must still produce the 5 screenshots (`01_home_play`, `02_class_pick`, `03_prologue_match`,
   `04_chapter_card`, `05_story_battle`) and exit 0 with no `printerr`. Keep `--scale`, `--reduced-motion`, `--out` working.
4. Check `docs/` for a mention of the story preview command (`git grep -n story_preview -- docs README.md tools`) and fix it if the usage changed.

## Constraints
Minimal change; no game-code change unless diagnosis proves a real bug (then report, don't fix). Do not touch `.claude`, `.ai/checkpoint.md`, assets, CI.
Do not commit or push. Do not use `git show ref:path` in this shell. One Godot process at a time.

## Verify (paste exact lines)
- Before: the failing run above prints the error (confirm).
- After: the same command exits 0 and writes all 5 PNGs; view `05_story_battle.png` and `03_prologue_match.png` and describe them.
- `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> 0 failed, smoke scripts pass (baseline first).

## Report (under 200 words)
Root cause (with evidence), what you changed, exit code + screenshot list, test counts before/after.
