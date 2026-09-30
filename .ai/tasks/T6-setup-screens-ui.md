# T6 — Character setup screens (Class/Skill tree, Races, Boons) match the AAC reference (client only)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG.
Read `CONTEXT.md` and **`docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md`** first (server side already exists
on this branch: commands `set_loadout`, `buy_race`, `tree_upgrade`, `buy_prestige`, `reset_tree`, and the `profile` /
loadout fields in the room snapshot — read `src/match/` to learn the exact field names).

## Goal

Build the pre-match Character setup screens so they look as close as possible to the attached references
(`docs/references/aac_rogue/01_class_selection_and_skill_tree.png`, `02_race_selection_dwarf_traits.png`,
`03_boons_and_perks_setup.png`), reachable from the Room (lobby) screen before the Host starts.

## Files you may change

New files under `src/client/setup/`, `src/client/screens/lobby_screen.gd` (add the entry button and token handling),
`src/client/client_app.gd` (only to create/load the player token in `user://` and send it on join),
`src/client/ui/ui_text.gd` (append only). Do NOT change `src/match/**`, `content/**`, `tests/**` except adding UI-only tests.

## Layout (base 1280×720; reference pixels 1920×1080 × 2/3). Background: the tavern-like dark warm backdrop is fine as a
simple dark wood gradient; panels are the reference's **dark navy** (#1c2233-ish) with a light grey 2 px ornate-looking
border (corner diamonds), Pixelify Sans white text.

1. **Top icon bar**: 5 round dark medallion buttons centred at the top (Profile, Races, Class, Boons, Records) with simple
   drawn icons; the active one is brighter. **Finish** button bottom centre returns to the Room. Gems with a green gem icon
   bottom-left (`profile.gems`).
2. **Class** (ref 01): left title box "Class"; left panel with class name, a big drawn class icon, `<` `>` arrows, page
   dots, and the description + "Recommended Stats: DEX/LCK"; a "Skill Tree" button under it. Middle panel: selected node
   title, `Level: x/5`, effect text, `Cost: N` / `MAX`, `Status: Unlocked/Locked`, **Upgrade** button. Right panel:
   `Class (n)` title, `Prestige: n (MAX)`, the 7 node squares in a 3–3–1 layout joined by lines, each showing `x/5`;
   **Buy Prestige** and **Reset Skills** buttons with gem cost. Choosing a class in the carousel sends `set_loadout`.
3. **Races** (ref 02): left title box "Races" and a scrollable list of big race buttons (locked/unaffordable ones greyed
   with the gem price shown, e.g. `Dwarf 💎50`); right "Description" title box and panel: race name, each passive name
   and text, and **Purchase** (green) or **Select** button. Centre stays empty (the character shows through).
4. **Boons** (ref 03): one wide panel with three columns: left = details of the hovered/selected boon; middle = list grouped by
   headers `Slots: 5`, `Slots: 4`, ... with boon buttons (locked ones greyed) and a **Search...** box at the bottom; right =
   `Slots: x/5` and the equipped boons list (click to remove). Equipping over capacity is prevented with a tooltip.
5. **Profile** and **Records**: simple panels in the same style (player name, token-short id, current loadout; Records = best
   runs if available, otherwise "No records yet").
6. The Room screen shows each player's chosen Class/Race next to their name.
7. Keyboard: Tab/arrows/Enter on every button, Esc = Finish. Text scale and reduced motion respected; no overlaps at
   1280×720 or text scale 1.4.

## How to verify

1. `bash scripts/run_tests.sh` → 0 failed.
2. Extend `tools/ui_preview.gd` (you may edit it) to capture the Class, Races and Boons tabs, run it with and without
   `--scale=1.4`, compare with the references side by side, and fix differences until it looks right.

## Report (end your run with this, in English)

- Files changed; checklist 1–7 done/partial (why); test result line; screenshot paths; what you could not match

## Notes added 2026-09-29
- Class portraits: use `assets/characters/<class>/portrait.png` (Archer, Mage, Swordsman) via `SpriteSet` if present on this branch
  (`src/client/battle/sprite_set.gd`) or by reading `assets/characters/manifest.json`; Rogue/Guardian get a code-drawn icon.
- The home page is now `src/client/screens/title_screen.gd` + `src/client/home/`; add the Character setup entry to the Room/lobby
  screen as specified (not to the home page).
- Run only ONE Godot process at a time (machine is low on RAM).
