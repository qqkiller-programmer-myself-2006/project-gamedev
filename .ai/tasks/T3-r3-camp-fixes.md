# T3 round 3 — camp QA fixes

Continue on this branch. Same rules/file limits as `.ai/tasks/T3-camp-ui.md`. Round 2 looks close to the references at
scale 1.0 — keep it. This branch now also contains the server attributes (ADR-0012 §1): the snapshot has
`party[].attributes`, `party[].derived`, `party[].points` — read `src/match/attributes.gd` and `match_run.gd` for names.
QA of `build/r2_s3_final/10_rest.png` and `build/r2_s3_big4/10_rest.png` found:

1. **At `--scale=1.4` the equipment slot labels and the entire stat list are blank** (empty grey boxes). They must render
   at every text scale; shrink fonts inside fixed-size boxes if needed rather than hiding content.
2. **Stat sheet**: now show STR, DEX, CON, INT, FTH, CHA, LCK from `party[].attributes` and the derived block
   (Initiative, Crit Chance, Crit Damage, Block Chance, Block Damage Reduction, Dodge Chance, Aggro, Lifesteal, Energy Regen)
   from `party[].derived`, in the reference order with blank separator lines. Values column is clipped
   ("Level: 3 (16/4") — use one `Label` per line "Name: value" left aligned like ref 10, no separate value column.
3. **Invest Points (n)** opens a small panel with a `+` button per attribute sending `{"type":"invest","stat":"<attr>"}`.
4. **Region box overlaps "Forest (5/5)"** at 1.4 — place the box directly under the title, right aligned, never overlapping.
5. **Headings**: "Equipment" must use the same size as "Crafting" and "Inventory" (ref 08).
6. **Long names** ("Wisp-thread Robe", "Bramble Quiver" at 1.4) are cut by the buttons: wrap to two lines or shrink the
   font to fit; never draw under the buttons.
7. **Active tab** (Stash/Craft, Inventory/Abilities) is highlighted with a lighter fill and outline; inactive ones normal —
   not a disabled look.
8. Re-capture seeds 3 (Rest) and 11 (Merchant) at scale 1.0 and 1.4 and inspect every image for blanks, clipping and overlaps.

Verify: `bash scripts/run_tests.sh` → 0 failed (this branch now has 251 tests). Report in English: items 1–8, test line,
screenshot paths.
