# T25 — Icons on every screen, phase 2 (#61)

Read `AGENTS.md` ("Where things live"), `.claude/agents/icon-designer.md`, `docs/design/icons.md` (every icon and its meaning),
`docs/design/ui-style.md`, `src/client/ui/icons.gd` (`Icons.texture/rect/with_text`), and look at `assets/icons/_contact.png`
and the AAC references in `docs/references/aac_rogue/` (small icons beside labels).

Put icons beside text (never icon-only; tooltips where there is no room) on:
1. Battle HUD (`src/client/match/battle/`): Fight / Items / Focus buttons (fight, items, focus), Strike / Guard cards (strike,
   guard), skill cards (skill + energy cost with the energy icon), HP / Energy / Gold captions (hp, energy, gold), status badges
   on tokens (poison, bleed, burn, stun, weak, shield, regen, dodge, crit — map from the status ids in content), crit/dodge
   popups if simple.
2. Camp (`src/client/match/camp/`): column headers and tabs (items, weapon/armor/accessory/consumable slots, merchant, rest),
   Gold/Gems amounts, stat sheet rows (str dex con int fth cha lck + level/exp), Transfer (transfer), Ready (ready).
3. Title and lobby (`src/client/title/`, `src/client/lobby/`): menu buttons (play, multiplayer, story_mode, settings, credits,
   quit, back), character setup tabs and Gems.
4. Path vote cards (`src/client/match/vote_panel.gd`): encounter type icons (combat, elite, merchant, rest, treasure, story,
   class_trial, boss).

## Rules
- Use `Icons` only; colours stay in `UiKit`. Icons 16 px at 1x text, scale with the text-scale setting (2x for 1.4+).
- Do NOT edit `src/client/story/**` or `src/client/match/match_screen.gd` (another executor is changing them now).
- Keep layouts from overlapping at 1280x720, 1920x1080 and Extra-large text (`tools/dev/ui_preview.gd -- --resolution`).
- Tests: extend `tests/client/test_icons.gd` so every icon name referenced from `src/client/**` exists (scan for
  `Icons.` calls with string literals).
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
  (baseline 317); windowed `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --out=build/t25` and look at title,
  setup, vote, combat, merchant shots yourself. ONE Godot process at a time. Report in English: screens changed, test line.
