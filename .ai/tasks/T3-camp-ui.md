# T3 — Camp screen (Merchant / Rest) matches the AAC reference (client only)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG.
Read `CONTEXT.md`, `docs/adr/0011-rest-camp-crafting-gear-and-stat-points.md` and
`docs/adr/0012-aac-parity-attributes-focus-enemy-energy-personal-gold.md` first.

## Goal

Rebuild the camp screen so it looks as close as possible to the attached references
(`docs/references/aac_rogue/08_camp_crafting_and_inventory.png`, `09_equipment_grid_and_stats.png`,
`10_detailed_stats_breakdown.png`). The owner says the previous attempt "does not look like the pictures at all".
Match layout, proportions, colours, font and wording.

## Files you may change

`src/client/battle/camp_view.gd`, new files under `src/client/camp/`, and `src/client/ui/ui_text.gd` (append only, for new
UI strings — ADR-0007). Do NOT change `src/client/battle/battle_view.gd`, `battle_token.gd`, `battle_backdrop.gd`
(another agent is rebuilding them now), nor anything in `src/match/`, `src/net/`, `content/`, `tests/`.

## Layout (base 1280×720; reference pixels are 1920×1080, multiply by 2/3)

Style everywhere: flat medium-grey panels (~#5c5c5c) with a darker 2 px border, lighter grey rows (~#7b7b7b),
Pixelify Sans (`assets/fonts/`) white text with a dark outline, small secondary buttons in a darker grey.
Top-right keeps "Forest (layer/5)" + the small encounter box (same as combat). Top-left: small round icon buttons (menu ≡ with
Clues / Settings / Leave) instead of the text buttons.

1. **Column headings** in large pixel font above each column: "Crafting" (Rest) or "Shop" (Merchant), "Inventory", "Equipment".
2. **Left column**: a "Search..." text box that filters rows live. Rest: collapsible category headers `Charms (5)  –`
   (click toggles, count = recipes in that category) and recipe rows: large name on the left, two small stacked buttons on the
   right, **Craft** (blue text when all materials are present, red when not, disabled when not) and **Inspect**.
   Hovering or focusing Craft shows a grey tooltip box with one line per material: `2 Red Flower (0)` = needed amount,
   name, amount you have. Merchant: same row style with name, price and stock, buttons **Buy** (disabled with "Need N" tooltip)
   and **Inspect**; CHA discount is applied by the server — show the price the snapshot gives.
   Vertical tab buttons between the left and middle column: **Stash** and **Craft** (Rest) — Stash shows the shared bag in
   the left column; Craft shows recipes.
3. **Middle column "Inventory"**: "Search..." box; rows with large item name (+ `(x2)` count), and two small stacked buttons
   **Transfer** and **Inspect**. Transfer opens a small picker of Party members and sends
   `{"type": "transfer_item", "item": id, "to": slot_index}`; Equip for gear stays reachable by clicking a gear row
   (or an **Equip** button) as today. Bottom: gold box `N 🪙` (your character's `party[].gold`, falling back to the shared
   gold if absent) and a **Transfer Gold** button that opens a picker (member + amount) and sends
   `{"type": "transfer_gold", "to": slot_index, "amount": n}`. If the snapshot has no `party[].gold`, disable Transfer Gold
   and Transfer with a tooltip "Arrives with the next server update".
   Vertical tabs right of this column: **Inventory** and **Abilities** (Abilities lists the character's Skills with cost,
   cooldown and description). Under the tabs, a **Consumable** slot box showing `party[].consumable` or "Empty".
4. **Right column "Equipment"**: a 4×2 grid of square slots in this order: Helmet, Chestpiece, Leggings, Boots / Weapon,
   Charm 1, Charm 2, Charm 3. Each shows the equipped item's name (or "<Slot> Empty") with small corner buttons (unequip `–`,
   inspect). Small `<` `>` arrows next to the heading switch the viewed Party member (read-only for others).
   Below: a scrollable stat list exactly in the reference order: `HP: x/y`, `Energy: n`, `Level: n (exp/next)`, blank line,
   `STR`, `DEX`, `CON`, `INT`, `FTH`, `CHA`, `LCK`, blank line, `Initiative: a - b`, `Crit Chance: x%`, `Crit Damage: x%`,
   `Block Chance: x%`, `Block Damage Reduction: x%`, `Dodge Chance: x%`, `Aggro: x%`, `Lifesteal: x%`, `Energy Regen: n`.
   Values come from `party[].attributes` and `party[].derived` (ADR-0012 §1). If absent, show the current stats instead.
   Under the list: **Invest Points (n)** button (n = `party[].points`) that opens a small panel with `+` per attribute sending
   `{"type": "invest", "stat": "dex"}`; disabled at Merchant and when n = 0.
5. **Bottom**: centred **Ready (x/N) [R]** button (x/N from the snapshot as today) and the countdown next to it, and a **Hide**
   button bottom-right that hides all camp panels (showing only the backdrop and a "Show" button) and toggles back.
6. Keyboard: 1–9 craft/buy the listed rows, R ready, `/` focuses the search box, Tab/arrows/Enter work on all buttons.
   Reduced motion and text scale keep working. Nothing may overlap at 1280×720 or at text scale 1.4.
7. The client never decides results (ADR-0001) — every action is a command; show only the snapshot.

## How to verify (all must pass before you finish)

1. `bash scripts/run_tests.sh` → `0 failed` (GODOT env var is set).
2. `"$GODOT" --path . -s tools/ui_preview.gd -- --out=build/ui_t3 --seed=11 --speed=10 --class=rogue` and again with
   `--scale=1.4 --out=build/ui_t3_big`. Open the camp PNGs (Merchant and Rest) and compare them side by side with the
   references. Fix every overlap and every visible difference you can. Repeat until it looks right.

## Report (end your run with this, in English)

- Files changed, one line each
- Checklist of items 1–7: done / partial (why)
- Test result line and the screenshot paths you checked
- Anything you could not match and why
