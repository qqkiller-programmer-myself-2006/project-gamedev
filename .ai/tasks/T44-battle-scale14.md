# T44 — Battle screen at text scale 1.4: fix 3 layout bugs (production soon)

Reviewer screenshots (attached with -i): `build/q_1920x1080/04_combat_skills.png` and `build/q_1280x720/06_boss_skills.png`
(generated with `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/q_1280x720 --seed=11 --speed=10 --class=mage --scale=1.4 --resolution=1280x720`;
also try `--resolution=1920x1080`; $GODOT = D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe). The combat screen is main's #119 design
(`src/client/match/battle/battle_view.gd`, `combat_panel.gd`, `src/client/ui/ui_kit.gd`). Keep that design; fix only:

1. **Fight/skill menu** (Strike / Guard / Protect / Shield Wall...): at scale 1.4 the "Cost: N | Cooldown" line is clipped (the number
   after "Cooldown" is cut off), the 4th entry wraps to a second row, and the whole popup overlaps the combat log, the Turn/Ready/E2
   buttons on the right and hides back-row party tokens. Make it: never clip text (shorter label like "CD 2" if needed, or wrap
   inside the card), sit fully above the action bar without covering the log/side buttons (put it in a dedicated area, e.g. a
   scrollable grid with 2 columns at large scale, or replace the log area while open), and stay inside the viewport.
2. **Combat log** text is cut mid-word at the box edge ("Wren uses Fros", "takes 40 critica"): wrap with
   `autowrap_mode = AUTOWRAP_WORD_SMART`, scroll vertically, grow with scale.
3. **Enemy/boss info cards** over the stage clip long names ("Thornback Boar l..."): the name must shrink/ellipsize/wrap so level and
   HP bar stay readable; card must stay inside the viewport.
Also confirm Defend and Flee (Esc) are still reachable by mouse at scale 1.4 (they seem folded into the Fight menu); if there is no
visible way to Flee with the mouse, report it (do not add features).

Verify: regenerate screenshots into `build/q2_*` for 1280x720 and 1920x1080 at scales 1.0 and 1.4 (skills/items/targets states too:
`04_combat_skills`, `04_combat_items`, `04_combat_targets`, `06_boss_skills`) and LOOK at them. Extend a layout test under `tests/client/`
(e.g. `t35_layout_smoke.gd` pattern) to assert the skill menu stays inside the viewport and does not intersect the log or action bar.
Run the full suite (`GODOT=... bash tools/run_tests.sh`). Touch only `src/client/**`, `tests/client/**`, docs. Do not commit.
Report in English: what changed per bug, screenshot paths, test line, anything still wrong.
