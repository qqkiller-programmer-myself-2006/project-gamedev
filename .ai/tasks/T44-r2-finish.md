# T44-r2 — finish T44 (continue in this worktree; keep the uncommitted changes)

The previous Codex run was cut off. Reviewer results with the current uncommitted diff:
- Visuals are good: `build/q2_1280x720_s14/06_boss_skills.png` shows the skill menu as a 2x2 grid, "CD n" visible, no overlap.
- Full suite: 451 passed, **2 failed** (main alone passes 453/453, so the diff broke them):
  1. tests/client/test_accessibility_baseline.gd::test_enemy_weakness_stays_available_in_token_tooltip
  2. tests/client/test_accessibility_baseline.gd::test_primary_battle_actions_are_keyboard_focusable
Fix the CODE (not by weakening the tests) so these pass again, unless an assertion tests an old layout that T44 intentionally changed.
Also: at 1280x720 scale 1.4 the boss info card (top right) touches/covers the bottom of the `=` and `?` buttons; keep the card clear of them.
Check the three T44 bugs once more at 1920x1080 scale 1.4 (skill menu, combat log wrap, long enemy names such as "Thornback Boar")
with `ui_preview.gd ... --scale=1.4 --resolution=1920x1080` (output to `build/q4_1920`), and LOOK at the images.
Finish with the full suite (`GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`) -> exact summary line.
Only touch `src/client/**`, `tests/client/**`. Do not commit. Report in English: what changed, test line, screenshot paths.
