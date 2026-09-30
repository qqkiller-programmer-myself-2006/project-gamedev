# T1 — Combat screen matches the AAC reference (client only)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG.
Read `CONTEXT.md`, `README.md` (sections "Battle HUD (#25)") and `docs/adr/0012-aac-parity-attributes-focus-enemy-energy-personal-gold.md` first.

## Goal

Make the combat screen (Combat, Class Encounter Challenge, Guardian Boss) look as close as possible to the attached
reference images (`docs/references/aac_rogue/04_combat_layout_turn_order.png`, `05_combat_skill_selection.png`,
`06_skill_cast_action_banner.png`, `07_dot_status_stacking.png`, `11_dungeon_encounter_and_rewards.png`).
The owner says the previous attempt "does not look like the pictures at all". Match layout, proportions, colours,
font and wording. The game stays 2D; characters are drawn in code.

## Files you may change

`src/client/battle/battle_view.gd`, `src/client/battle/battle_token.gd`, `src/client/battle/battle_backdrop.gd`,
new files under `src/client/battle/`, and `src/client/ui/ui_text.gd` (append only, for new UI strings — ADR-0007).
Do NOT change anything under `src/match/`, `src/net/`, `content/`, or `tests/` — another agent owns them.

## What the screen must show (base resolution 1280×720; reference pixels are 1920×1080, multiply by 2/3)

1. **Font**: Pixelify Sans (`assets/fonts/`) for every label on this screen, white with a 1–2 px dark outline like the reference.
2. **Top-left**: replace the text buttons "Clues / Settings / Leave" with two small round dark icon buttons (menu ≡ and clues);
   the menu opens a small dropdown with Clues (C), Settings (F2), Leave. Keyboard shortcuts keep working.
3. **Left initiative list** (ref 04): "Turn N" in large pixel font above a narrow semi-transparent dark panel (~113 px wide).
   One compact entry per combatant in turn order: centred bold "Name (level)", a thin red HP bar with tiny "hp/max" text,
   a thin blue Energy bar with tiny "e/max" text. Current actor is highlighted (gold frame + `>` — do not rely on colour only).
   Controller tag (YOU/P2/AI/FOE) stays in the tooltip.
4. **Top-right**: "Forest (layer/5)" in large pixel font (also during the boss: show the layer, not "Boss"), and under it a
   small dark box with two short lines (encounter name in quotes, then "All") like `"Jumpscare" All` in the reference.
5. **Units on the field**: party on the left half, enemies on the right half, scattered on a dark grass field like ref 04.
   Replace the purple pawn placeholders with **blocky Roblox-style figures drawn in code** (head, torso, arms, legs as
   rectangles with simple shading; each party member a distinct outfit colour; Rogue holds a dagger). Enemies get
   recognisable blocky shapes by id: bee (yellow/black stripes, wings), spider (black box, red eyes, legs), rat (grey),
   wolf (grey quadruped), boar, humanoid bandits/outlaws, bramble archer, and a larger boss. Keep `BattleToken` as the
   component so sprites can replace it later.
6. **Nameplate under every unit** (ref 04/07): near-black semi-transparent box, small name at top-left, then a red HP bar with
   centred "hp/max" and a blue Energy bar with centred "e/max" side by side. Enemies show the blue bar only when the
   snapshot has `enemies[].energy` (ADR-0012 §3; the server adds it soon) — otherwise hide it.
7. **Status icons** (ref 07): small dark squares above the nameplate, left-aligned, each with a coloured gem icon
   (Bleed red, Poison green, Toxin purple, others from `statuses.<id>.color`) plus the abbreviation and stack count so
   colour is never the only cue. Tooltip keeps the full text.
8. **Bottom HUD** (ref 04): centred dark panel (~511×75 px). Row 1: "Class Lvl N (exp/next)" left, action-window seconds
   ("30s" style) centre, gold amount + coin icon right (use `party[].gold` of your character when present, else the shared gold).
   Row 2: red HP bar "hp/max" and a single continuous blue Energy bar "e/max" side by side, equal widths.
   Row 3: three equal grey buttons **Fight / Items / Focus**. Not your turn → hide row 3 (ref 06).
9. **Fight grid** (ref 05): pressing Fight opens a grey panel directly above the HUD (~457×140 px, must not cover any
   nameplate or the HUD). 3 columns of cards: **Strike** (= `attack` command), **Guard** (= `defend`), then each Skill.
   Card = square icon + name in pixel font + small "Cost: x | Cooldown: y". Unusable cards are dimmed with the reason in a
   tooltip. Items opens the same kind of panel listing usable items. **Focus** sends command `{"type": "focus"}` when
   `choices.focus` is true; otherwise the button is disabled with tooltip "Focus arrives with the next server update".
10. **Cooldown boxes** to the right of the HUD (ref 06): small dark squares, first an hourglass icon, then one box per Skill
    showing remaining cooldown (a tick/"OK" when ready); tooltip shows the Skill name so Skills are distinguishable.
11. **Action banner** (ref 06): full-width dark grey stripe across the lower third, tilted about −1°, skill/item/boss move
    name centred in pixel font, using the display name from the snapshot/content (not the id). Attack/Defend are announced
    as Strike/Guard. It must not overlap the Fight grid (hide the grid while the banner shows).
12. **Rewards** (ref 11): after a win, bottom-left large pixel text lines: item/material name(s), "+N Gold" in yellow, "N EXP".
13. Floating damage numbers: DoT ticks coloured by status with abbreviation; simultaneous numbers stack upwards, never overlap.
14. Keep all existing keyboard controls working: A/S/D/I become F (Fight) / I (Items) / O (Focus), keep S and D as aliases,
    1–9 pick cards/targets, Esc goes back. Keep Reduced motion and text-scale settings working.
15. The client never computes game results (ADR-0001) — display only what the snapshot/events give.

## How to verify (all must pass before you finish)

1. `bash scripts/run_tests.sh` → still `248 passed, 0 failed` (GODOT env var is already set).
2. Screenshots: `"$GODOT" --path . -s tools/ui_preview.gd -- --out=build/ui_t1 --seed=11 --speed=10 --class=rogue`
   and again with `--scale=1.4 --out=build/ui_t1_big`. Open the combat/boss PNGs and compare them side by side with the
   reference images. Fix every overlap and every visible difference you can. Repeat until it looks right.
3. No text overlaps anything at 1280×720 or at `--scale=1.4`.

## Report (end your run with this, in English)

- Files changed, one line each
- A checklist of items 1–15 above: done / partial (why)
- Test result line and the screenshot paths you checked
- Anything you could not match and why
