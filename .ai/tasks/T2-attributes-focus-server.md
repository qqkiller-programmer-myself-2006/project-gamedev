# T2 — Server: 7 attributes, derived stats and the Focus command (ADR-0012 §1–§2)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG with an authoritative server.
Read these first: `CONTEXT.md`, `docs/testing.md`, `docs/adr/0011-rest-camp-crafting-gear-and-stat-points.md` and
**`docs/adr/0012-aac-parity-attributes-focus-enemy-energy-personal-gold.md` (the spec for this task — sections 1 and 2 only)**.

## Files you may change

`src/match/**`, `content/forest.json`, `tests/**`, `tools/simulate.gd`, `docs/balance.md`, `CONTEXT.md`.
Do NOT change `src/client/**` — another agent is rebuilding the client UI in parallel.

## What to build

1. **Attributes** (`str, dex, con, int, fth, cha, lck`) for party characters, stored per character in the match state.
   - Add `classes.<id>.attributes` (starting values) and `classes.<id>.base` (base stats) and `classes.<id>.atk_attr`
     (`"str"` or `"dex"`) to `content/forest.json`. Choose starting attributes that fit each Class
     (Swordsman STR/CON, Archer DEX/LCK, Mage INT/FTH, Guardian CON/STR, Rogue DEX/LCK, Classless spread evenly), then set
     `base` so that **the derived stats at level 1 equal today's `classes.<id>.stats` exactly** (max_hp, atk, def, mag, res,
     spd, crit). Keep `stats` only if other code still needs it; otherwise remove it.
   - One place (a small module, e.g. `src/match/attributes.gd`) computes derived stats from base + attributes + gear
     using the table in ADR-0012 §1. Every existing reader of character stats must go through it.
   - New derived stats: `crit_damage`, `dodge`, `block`, `block_reduction` (0.5), `aggro`, `lifesteal`, `energy_regen`,
     `initiative`. Wire dodge, block, aggro, lifesteal and crit_damage into combat exactly as ADR-0012 §1 says.
     Events for direct hits get `dodged: true` / `blocked: true` when that happens.
   - CHA discount at the Merchant for the buying character; LCK drop-chance bonus for the character that landed the kill;
     FTH healing bonus.
   - Level-up: `leveling.points_per_level = 2`; `invest {stat}` now accepts attribute names (1 point = +1 attribute) and
     rejects old stat names with the existing error code for bad input. AI invests in `invest_focus` (now an attribute name).
   - Gear `items.<id>.gear.stats` may now also contain attribute keys; keep existing gear working.
   - Snapshot: `party[].attributes`, `party[].derived` (initiative, crit, crit_damage, dodge, block, block_reduction,
     aggro, lifesteal, energy_regen), `party[].points`.
2. **Focus command** `{"type": "focus"}`: allowed on the character's own turn in Combat, Challenge and Boss; ends the turn,
   gives +1 Energy immediately (capped at `energy_max`) and +10% dodge until the start of that character's next turn.
   `choices.focus = true` when it can be used. Event `action_resolved` with `action: "focus"`. AI may use Focus when it
   cannot afford any Skill and Energy is below its cheapest Skill cost — only if balance stays in range.
3. Update `CONTEXT.md` glossary: Attribute, Derived stat, Focus, Strike (= Attack), Guard (= Defend). Keep the existing style.

## Rules you must keep

- All randomness through the injected `GameRng`, all time through the injected clock (no engine randomness/time in `src/match`).
- Tests only through the Match interface (`MatchServer`) as `docs/testing.md` describes.
- Content numbers live in `content/forest.json`, not in code.

## How to verify (all must pass before you finish)

1. `bash scripts/run_tests.sh` → 0 failed. Existing tests should keep passing because level-1 derived stats equal the old
   stats; if a test fails because a rule intentionally changed (e.g. invest now takes attributes), update that test and say so.
2. Add new tests (new file `tests/match/test_attributes.gd`, plus Focus tests): derived stats at level 1 equal old stats for
   every Class; each attribute's effect from the ADR table; invest rejects bad names; dodge/block events with a seeded RNG;
   Focus gives +1 Energy capped and the dodge bonus expires; `choices.focus`; snapshot fields present.
3. Balance: `"$GODOT" --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2` → win rate for both modes
   must stay within 70–97%. Put the numbers in `docs/balance.md`. If out of range, tune content numbers (not code).

## Report (end your run with this, in English)

- Files changed, one line each
- Final attribute/base table per Class
- Test result line (passed/failed count) and the simulate.gd win rates
- Any test you changed and why; anything from the spec you could not do
