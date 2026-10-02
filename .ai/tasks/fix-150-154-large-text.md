# Task: fix #150 (camp Tip covers encounter name) and #154 (BattleView overlaps) — large text / small viewports

Read: `AGENTS.md`, `CONTEXT.md`, `docs/guides/testing.md`, `tools/dev/ui_preview.gd`, existing layout smoke tests in `tests/client/`
(e.g. `menu_position_smoke.gd`, `dialogue_log_smoke.gd`, `t46_skill_menu_layout_smoke.gd`) for how layout is asserted headlessly.
Issue texts (use them if `gh` is denied):

## #150
First Rest camp: tutorial Tip overlaps the encounter name badge ("Hollow Oak") at 1280x720, text 1.4x.
`src/client/match/camp/camp_view.gd:80-82` badge at (112,12); `:110-116` Tip at (152,48) min width 360 -> intersect; `:138` auto-opens hint.
Expected: encounter name stays readable while Tip is visible. Verify Rest AND Merchant at 1280x720 and 1920x1080, scales 1.0 and 1.4.

## #154
BattleView overlaps: (a) 1024x768 @1.0: full-width "Your turn!" banner crosses top of Skill cards and covers Tip text;
(b) 1024x768 @1.45: Guardian name/header collides with right-aligned "Forest (Boss)" location badge, target prompt and Tip partly obscured;
(c) ~1924x1061 @1.45: turn banner crosses bottom status row and hides a Skill cost; Guardian header collides with location badge.
Evidence: `src/client/battle/battle_view.gd` turn banner anchored at 71% viewport height (~160-163), HUD bottom-anchored and grows with cards (~151-156, 461+);
boss header and location badge use separate fixed placements.
Expected: banners, Skill/Item cards, status values, Tips, Boss phase/location labels readable without overlap at supported size/scale combos.

## Do
1. Diagnose with real rects (get_global_rect) in a throwaway probe at the listed sizes; fix root causes in layout code (position the banner
   relative to the HUD top / safe area, stack or wrap the boss header vs location badge, place the camp Tip clear of the badge). No magic offsets that
   only work at one size.
2. Add headless layout smoke script(s) in `tests/client/` (standalone `extends SceneTree`, non-`test_` name, quit(0|1); auto-discovered by
   `tools/run_tests.sh`) asserting no intersection between the named controls at the issue's sizes/scales. Keep `.uid` with scripts.
3. If cheap, real screenshots with the non-console exe `Godot_v4.7.2-stable_win64.exe --rendering-driver opengl3` via `tools/dev/ui_preview.gd`
   into `docs/screenshots/`; view and describe them. Skip and say so if not cheap.
4. i18n: only if strings change (`tools/i18n/`).

## Constraints
Layout-only; no gameplay/logic change. Don't touch `.claude`, `.ai/checkpoint.md`, assets, CI. No commit/push. One Godot process at a time.
`GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`. No `git show ref:path` in this shell.

## Verify (paste exact lines)
Baseline `bash tools/run_tests.sh` before; after: 0 failed, new smoke scripts pass; `--headless --path . --import` exit 0; `git status --short`.

## Report (under 200 words)
Root causes, what moved, sizes covered, screenshots (paths + what you saw), counts.
