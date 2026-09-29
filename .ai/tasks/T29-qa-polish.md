# T29 — QA polish from the 1920x1080 / large-text pass (#54)

Screens captured with `tools/dev/ui_preview.gd -- --seed=7 --resolution=1920x1080` and `--scale=1.4`. Fix:

1. **Region title in the cave**: the top-right header says "Forest (5/5)" on Layer 5 and at the boss, which now happen in the
   cave. Show the region per layer from content (e.g. `journey.regions` {"1".."4": "Forest", "5": "Cave"} and boss "Cave"; add
   the content key; fallback "Forest"). Same wherever the region name is shown (match screen header, summary).
2. **Nameplates overlap at large text** (`src/client/match/battle/`): at text scale 1.4 the three front party plates overlap and
   the Energy caption "1/6" is clipped. Keep plates inside their slot width (shrink font inside the plate, or clamp plate width to
   the slot spacing) so nothing overlaps at 1.0, 1.2, 1.4 (Extra-large) on 1280x720.
3. **Merchant tip is outdated**: it says "Anyone can buy with the Party's shared Gold". Gold is personal now (ADR-0012): say each
   character buys with their own Gold and can Transfer Gold. Check the other tips/hints in `src/client/ui/ui_text.gd` for the
   same outdated "shared Gold" wording.
4. **Camp equipment slot labels wrap mid-word** at large text ("Weapo n", "Charm 1" split): shorten or use autowrap off +
   ellipsis/clip, or icon + short label; no mid-word breaks.
5. **Class setup shows the id in lowercase** ("assassin") as the class name: use the content class `name` (check
   `content/forest.json` classes.<id>.name exists for every class after the Rogue→Assassin rename; add if missing), fallback
   `capitalize()`.
6. **Skill tree nodes show "*"** placeholders: show the node's icon (use `Icons` — e.g. skill/str/dex/... by node kind) or its
   short name; keep "0/5".

Files: `src/client/**`, `content/forest.json` (names/region keys only), `tests/client/**`.
Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe; "$GODOT" --headless --path . --import; "$GODOT" --headless --path . -s tests/run_tests.gd`
→ 0 failed (baseline 362); windowed `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --scale=1.4 --out=build/t29` and
look at 02a_setup_class, 06_boss_turn, 08_merchant yourself. One Godot process at a time.
