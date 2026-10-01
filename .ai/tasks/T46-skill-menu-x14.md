# T46 — Battle skill menu overlaps the HUD and clips at text 1.4 (main 0b1fa76)

Client only: `src/client/match/battle/**`, `tests/client/**`. Theme: `docs/design/ui-style.md`, `UiKit`. File: `src/client/match/battle/battle_view.gd`
(skill grid built for `combat_mode == "skills"`; targets use `combat_mode == "attack"`). Method reference: `tests/client/t43_camp_battle_fit_smoke.gd`
(real global rects at scale 1.4 with 5 party members; the scale must really be applied via `ClientApp.apply_settings()`).

Repro: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t46 --seed=11 --scale=1.4 --resolution=1920x1080 --class=rogue`
Look at FULL resolution: `04_combat_skills.png`, `04_combat_targets.png`, `04_combat_items.png`; also 1280x720 at scales 1.0 / 1.2 / 1.4 and `--seed=3`.

Seen at 1.4:
1. **Skill menu** (the grid "[1] Strike ... [4] Shield Wall") is drawn over the right-hand status chips (Turn / P / S) and the bottom-left battle log.
   Its second row ("[4] Shield Wall") and the "Cost / Cooldown" lines are cut off at the bottom of each cell.
2. **Enemy nameplate** is truncated ("Thornback Boar L"): the level text is cut.
3. **Target prompt** ("Choose a target on the field (1-5), Esc to go back") sits on the edge of the battle log box.

Do:
- Make the skill menu fit without covering the chips, the log or the bottom action bar: e.g. dock it in the free band above the action bar,
  wrap the grid to the available width, give every cell enough height for name + cost/cooldown at 1.4, or scroll the grid. Skills remain
  reachable by keys 1-9 and by mouse; keep tooltips and focus order.
- Nameplates: shrink or wrap so name and level both stay visible (ellipsis on the name, never on the level).
- Target prompt: move it so it does not overlap the log or any nameplate.
- Add real-rect assertions (extend a standalone smoke test script in `tests/client/`, same style as t43; keep it exit-code based) for the skill
  menu, chips, log and prompt at 1.4 / 1.0, inside the viewport and not intersecting each other. Do not weaken existing tests.
- The layout smoke scripts (t35/t42/t43/t88) run in CI; keep all of them passing: run each with
  `"$GODOT" --headless --path . -s tests/client/<name>.gd` (exit 0).
Verify: `bash tools/run_tests.sh` -> 0 failed (>= 452 passed) and the four smoke scripts above exit 0; LOOK at the full-resolution previews.
Report (<150 words). Do not commit or push.
