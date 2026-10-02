# Task: U33 Story dialogue box must not cover the event log

Problem (seen in a real Godot window at 1280x720, text scale 1.0, Story match prologue): the Story `DialoguePanel`
(`src/client/story/dialogue_panel.gd`, hosted by `StoryDirector` inside `MatchScreen`) is anchored to the bottom with
`offset_left` ~ party-column width + 32 and `offset_bottom = -14`, so it overlaps the bottom event-log panel
(`MatchScreen._log`, the full-width bar at the bottom: y ~610-700): the log's right part and its text are hidden while the
dialogue is up. The dialogue box must sit ABOVE the log (it may cover the center panel; it must not cover the log, the header,
or the party column).

Do:
1. Let `MatchScreen` tell the Story director/dialogue where the log starts (e.g. a `bottom_inset` / `set_safe_bottom(y)` computed from
   the log panel's global rect top minus a margin, refreshed when layout changes, text scale changes, or the log resizes), and use it in
   `DialoguePanel._layout()` so `offset_bottom = -(viewport_height - log_top + margin)`. Keep the content-sized height logic (U33),
   clamp so the box still fits and never goes above the header; fall back to the current -14 when no inset is provided (the
   standalone `tools/dev/story_preview.gd` harness adds the panel without a MatchScreen, and `tests/client/test_ui_polish_restore.gd`
   / story UI tests build it directly — keep them passing).
2. Keep everything else: left offset, portrait/narrator drawing, typewriter, skip/advance keys, reduced-motion handling, `apply_settings`.
3. Add a smoke script `tests/client/dialogue_log_smoke.gd` (extends SceneTree, `quit(0|1)`; follow the pattern of
   `tests/client/menu_position_smoke.gd` / `t35_layout_smoke.gd`; run_tests.sh auto-discovers non-`test_` scripts in tests/client) that builds a real
   MatchScreen with an active Story dialogue and asserts the dialogue's global rect does not intersect the log panel's rect and stays inside
   the viewport, at text scale 1.0 and 1.4 and window sizes 1280x720 and 1920x1080. Keep `.uid` files.
4. Verify: record the baseline first, then `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`
   -> 0 failed and all smoke scripts pass. Capture a screenshot of the real Story prologue match with the dialogue up
   (non-console `Godot_v4.7.2-stable_win64.exe --rendering-driver opengl3`; tools/dev/story_preview.gd `--full` gives
   `03_prologue_match.png` — it fails later at the combat step on main too, ignore that) and save as `docs/screenshots/u33_dialogue_above_log.png`.

Constraints: minimal change; do not touch `.claude`, `.ai/checkpoint.md`, assets, CI. Do not commit or push. Do not use `git show ref:path` in this shell. One Godot process at a time.

Report (under 150 words): how the inset is passed, files changed, test counts before/after, screenshot path.
