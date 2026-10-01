# T-ui-battle-camp-gamefeel — make Battle + Camp HUD feel like a game and fix proportions

Owner request: "make the UI/UX look more like a game and better proportioned". You own the BATTLE and CAMP screens only.
Another agent (Claude) is editing title/lobby/match-list/ui_kit in parallel, so stay in your files.

## Files you may edit
- src/client/match/battle/*.gd (except battle_token.gd / battle_backdrop.gd art drawing)
- src/client/match/camp/*.gd
- tests/client/** (update/add tests when behaviour changes)
DO NOT edit src/client/ui/ui_kit.gd, title/, lobby/, match_screen.gd, vote_panel.gd, summary_panel.gd, or any server code (src/match, src/net).
If you need a new theme variation, build it locally with `UiKit` tokens (never hex literals) or note it in your report.

## Look first
Run: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/before --seed=3 --speed=10 --resolution=1920x1080`
(first run `"$GODOT" --headless --path . --import` once in this fresh worktree). Open build/before/04_combat_turn.png, 04_combat_items.png,
04_combat_targets.png, 06_boss_turn.png, 07_boss_warning.png, 08_merchant.png, 11_combat_reward.png.
Style rules: docs/design/ui-style.md (Navy + Gold). Reference for look: docs/references/aac_rogue/04–11.

## Problems to fix (seen in the 1920x1080 captures)
1. Turn-order timeline (left column in battle): rows are translucent over the scene, names/numbers barely readable, the column is clipped
   at the left screen edge, row heights are uneven. Make it a clean game-style turn-order bar: solid HudPanel rows, small portrait/colour chip,
   name + HP bar + energy pip, current actor highlighted in gold, consistent 8-12 px gutter from the screen edge. Consider a compact top
   or left strip that does not hide units.
2. "Turn 1" label is raw white oversized text with no panel. Put it in a TitleTag/HudPanel badge (Pixelify heading font) with the round counter.
3. Combat log (bottom-left) uses a huge font and crops lines. Use the "small" size, a HudPanel, newest line at the bottom, fixed height ~ 18% of
   screen height, width matched to the timeline column.
4. Bottom action bar: Fight/Items/Focus buttons, HP/Energy bars, "Turn / Ready / E2" tiny buttons are different heights and unbalanced.
   Centre the action bar horizontally, give the three actions equal width and icon + label, make the right-hand mini buttons the same height
   as the action row and add real labels or tooltips. HP and Energy bars the same height, labelled consistently.
5. Unit nameplates under the characters: text too small, bars cramped. Increase to theme `small` size, keep widths equal, keep them from
   overlapping neighbouring tokens at 1280x720 and at text scale 1.4.
6. Forest (1/5) title and the path tag at the top right: align as one tidy group (location + step pips like "1/5") with the same gutter as the menu buttons on the left.
7. Camp / Merchant (08_merchant.png): the Tip box overlaps the Shop column bottom; column heights are uneven; the Inventory/Equipment titles
   float at different heights. Give the three columns equal top/bottom, same title-tag style and move the Tip to the top bar or above Ready.
   Ready button + timer should sit centred under the middle column.
8. Make interaction feel game-like with cheap polish (respect reduced motion = `ClientSettings` flag already used elsewhere):
   hover/pressed scale or glow on action buttons, short fade/slide-in of the action bar when it becomes the player's turn,
   subtle pulse on the acting unit's ring, HP bar tween when it changes. No new assets.

## Verify
- `GODOT=<godot console exe> bash tools/run_tests.sh` all passing (baseline in .ai/checkpoint.md; do not lower the count).
- Re-run ui_preview at 1920x1080 and 1280x720, and with `--scale=1.4`, output to build/after*. Nothing overlaps, nothing clipped, one gold primary per panel.
- Report: list of changed files, each numbered problem fixed / not done (+why), exact test summary line, and the paths of the final screenshots.
Do not commit or push.
