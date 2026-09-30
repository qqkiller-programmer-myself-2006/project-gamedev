# T30 — Match rule fixes from the full QA report (#78, #79, #80)

Source: `docs/review/2026-09-30-full-qa-report.md` (B1–B9). Server/rules only: `src/match/**`, `src/net/**` if needed for B9,
`tests/match/**`. Do not touch `src/client/**`. Each fix gets a test that fails before and passes after.

1. **B1 (#78, P1)** `src/match/match_run.gd` ~line 317 in `grant_exp`: `character["points"] += _tree_level(character, "stat_points")`
   pays the Stat Points node on every level-up. ADR-0013 says "+1 *starting* attribute point per level". Delete that line
   (the correct starting grant is already ~line 406). Test: node at 5/5, level up → points grow by `points_per_level` only.
2. **B2 + B3 (#79, P1/P2)** Shield Wall (`shields[id]` in `combat_encounter.gd`, cleared only at the caster's own turn start) keeps
   the party at 60% damage after the Guardian dies; a death from a direct hit does not clear statuses (DoT death does).
   Add ONE death helper called from `_hit` and `_tick_statuses`: clear that unit's shields, Protect entries it gave/holds,
   `defending`, `focusing` and `status_book.clear_unit(id)`; dead enemies must also lose their status badges in `_enemy_views`.
   Tests: Guardian dies after Shield Wall → damage back to 100%; a hero revived (Spirit Bloom) has no old Bleed/Poison ticking.
3. **B4** Boss counted as an extra Layer for Gems (`match_run.gd` ~852): win gives 110, must be 100 (6×10+50). Only increment
   `layers_passed` when `phase != "boss"`. Test the Gems total for a full win.
4. **B5** `party_ai.gd` ~36–40: AI spends real Stash consumables in a non-lethal Class trial (HP restored afterwards). Skip
   `_healing_item` when `combat.trial` is set.
5. **B6** `party_ai.gd` ~195–208: AI never uses its own Consumable slot. Also look at `me["consumable"]` when healing.
6. **B7** `enemies.skeleton.resistances` in `content/forest.json` is never read. Apply it in `_hit` next to `weakness` (keep the
   description true), with a test that a physical hit on a skeleton is reduced.
7. **B8** `craft` accepts dotted ids (`pelt_boots.materials`) and gives a free junk item (`match_run.gd` ~442–453). Exact key match
   on `crafting.recipes`, reject otherwise. Test with the dotted id.
8. **B9** Malformed numeric fields (`{"type":"vote","option":[1]}`) raise script errors and get no `result`
   (`room.gd` ~145, `combat_encounter.gd` ~108, `match_run.gd` ~762, `class_encounter.gd` ~64, `transfer_*`). Validate types in
   `MatchServer.command` (or a single guard it calls) and reply `invalid_command`. Tests: array/dict/string where an int is
   expected for vote, target, slot, transfer amount.

Rules: keep changes small; follow the surrounding style and comment density; use the CONTEXT.md vocabulary; no new files
except tests. B1 and B2 change difficulty, so rerun the simulation (below) and report the numbers.

Verify (one Godot process at a time; `$GODOT` is already set by the runner to the console exe):
`"$GODOT" --headless --path . --import` then `bash tools/run_tests.sh` → 0 failed (baseline 368 passed; new tests add to it).
Balance: `"$GODOT" --headless --path . -s tools/dev/simulate.gd -- --seeds=100 --humans=1,2` — baseline from the QA report:
win 80 / 75 (1 human default / loadout), 77 / 90 (2 humans); target 70–92 in every mode. If any mode leaves 70–92, report it —
do not retune content on your own.

Report (under 200 words): per item done / not done, the exact test summary line, the simulation win rates, changed files,
stray files. Do not commit or push.
