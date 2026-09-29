# T3 round 2 — camp screen QA fixes

Continue the camp screen work already on this branch (`src/client/battle/camp_view.gd`).
Same rules and file limits as `.ai/tasks/T3-camp-ui.md` (read it again). QA captured `build/qa_s3/10_rest.png` and
`build/qa_s11/08_merchant.png` (seed 3 reaches a Rest, seed 11 a Merchant) and compared them with refs 08–10.
Fix every item, then re-capture both seeds at scale 1.0 and 1.4 and compare again.

1. **Colours are too dark.** Reference panels are medium grey (~#5c5c5c) with lighter grey rows (~#7b7b7b), white text with
   a dark outline, small buttons a slightly darker grey (~#4a4a4a). Ours is near-black (#2b2b2b). Match the reference.
2. **Rows are too tall and the buttons too big.** Reference row: item name in large pixel font on the left, two *small*
   stacked buttons on the right (small font, ~1/4 of row width). Row height ≈ 2 small buttons. Remove the empty space.
3. **Search box** of the left column is clipped at the top of the scroll area. Put each column's "Search..." as a fixed strip
   directly under the column heading, outside the scroll list (ref 08), for all three list columns.
4. **Tabs**: Stash/Craft (and Shop) must be **vertical buttons between the left and middle column**, and Inventory/Abilities
   vertical buttons to the right of the middle column, with the **Consumable** slot box below them (ref 08). Not inside the list.
5. **Craft button text colour**: blue when craftable, red when not (keep it disabled when not). Currently dark grey.
6. **Stat sheet is wrong.** Without `party[].attributes` it shows the old stats under attribute names (STR = atk,
   CON = max_hp...) — that is misleading. If attributes are missing, show the old stat names (ATK, DEF, MAG, RES, SPD); once
   they are present, show STR…LCK. Crit Damage shows "1.5%": it must be a percentage of the multiplier (150%). Add the blank
   separator lines from the reference. The **Invest Points (n)** button must always be visible under the stat list (outside
   its scroll), like ref 08.
7. **Equipment grid** leaves empty space on the right; the 4×2 slots must fill the column width as larger squares with the
   item/slot name centred in bold (ref 09), small corner buttons.
8. **Region box**: under "Forest (layer/5)" add the small dark box with the encounter name in quotes and "All", same as the
   combat screen.
9. **Gold row** (gold + Transfer Gold) must always be visible at the bottom of the Inventory column (outside the scroll);
   in the Rest screenshot it is scrolled away.
10. At `--scale=1.4` the right column is clipped (Charm 3 and the `>` arrow go off-screen). Nothing may leave the screen.

Verify: `bash scripts/run_tests.sh` → 0 failed; `"$GODOT" --path . -s tools/ui_preview.gd -- --out=build/r2_s3 --seed=3
--speed=10 --class=rogue` and `--seed=11`, each also with `--scale=1.4`.
Report in English: each item 1–10 done/partial, test result line, screenshot paths.
