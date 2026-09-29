# T4 — Server: enemy Energy, personal Gold, Transfer Gold/Item, Consumable slot (ADR-0012 §3–§4)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG with an authoritative server.
Read first: `CONTEXT.md`, `docs/testing.md`, `docs/adr/0011-rest-camp-crafting-gear-and-stat-points.md` and
**`docs/adr/0012-aac-parity-attributes-focus-enemy-energy-personal-gold.md` sections 3 and 4 (the spec for this task)**.
Sections 1–2 (attributes, Focus) are already implemented on this branch — build on them, do not redo them.

## Files you may change

`src/match/**`, `content/forest.json`, `tests/**`, `tools/simulate.gd`, `docs/balance.md`, `CONTEXT.md`.
Do NOT change `src/client/**` (another agent owns the client).

## What to build

1. **Enemy Energy** (§3): every enemy and the Guardian Boss has Energy — starts 0, +1 at the start of each of its turns,
   capped at `enemies.<id>.energy_max` (default `rules.enemy_energy_max = 4`; boss 6).
   Add `enemies.<id>.special` = `{name, energy, ...same shape as an attack profile...}` to at least 3 Forest enemies
   (e.g. Grey Wolf "Rend" applies Bleed; a spider/bee type applies Poison; a bandit type hits twice) and let enemies use
   their special when Energy is enough, otherwise their normal attack/behaviour. Decide how the boss spends Energy so its
   existing pattern still works (document it in the ADR's spirit in `docs/balance.md`).
   Snapshot: `enemies[].energy`, `enemies[].energy_max`; the round order/timeline data includes enemy energy too.
   Event `action_resolved` for a special includes `name` (display name) and `energy_spent`.
2. **Personal Gold** (§4): `party[].gold` per character replaces the shared Party gold. Reward gold is split evenly between
   the characters still in the Party (remainder to the lowest slot). Treasure gold the same way.
   Merchant `buy` spends the buying character's gold at the CHA-discounted price (already computed per buyer).
   Keep any old shared-gold field only if something still needs it; the snapshot must expose per-character gold.
3. **`transfer_gold {to, amount}`** at Merchant and Rest: from the sender's own character to any Party slot; reject bad
   amounts / not enough gold / wrong phase with error codes in the existing style.
4. **AI gold**: when a Merchant or Rest opens, AI characters give all their gold to human players split evenly
   (remainder to the lowest human slot). Emit an event so the log can show it.
5. **Stash + Consumable slot**: the shared bag is the Stash. Each character has one Consumable slot
   (`party[].consumable = {item, count}` or null). `transfer_item {item, to}` at Merchant/Rest moves one consumable item
   (not material, not gear) from the Stash into that character's slot (same item stacks; a different item swaps the old
   one back to the Stash). In Combat the `item` command uses the acting character's Consumable slot first, then the Stash.
6. Update `CONTEXT.md` (Gold is personal; Energy — enemies have Energy; Stash; Consumable slot; Transfer) and mark
   ADR-0011's shared-gold rule as superseded by ADR-0012 §4 (edit ADR-0011's front matter/status line only).

## Rules you must keep

- Randomness only through `GameRng`, time only through the injected clock; tests only through `MatchServer`.
- Content numbers live in `content/forest.json`.

## How to verify (all must pass before you finish)

1. `bash scripts/run_tests.sh` → 0 failed. Update tests that assumed shared gold or energy-less enemies and say which.
2. New tests (`tests/match/test_enemy_energy.gd`, `tests/match/test_personal_gold.gd`): energy gain/cap/reset, special used
   only when affordable, snapshot fields; reward split with remainder; buy spends buyer's gold; transfer_gold rules and errors;
   AI gold handed to humans; transfer_item into the Consumable slot and swap; combat item uses the slot first.
3. `"$GODOT" --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2` → both modes within 70–97%; record in
   `docs/balance.md`; tune content numbers if needed.

## Report (end your run with this, in English)

- Files changed, one line each; enemy specials added (name, cost, effect)
- Test result line and simulate.gd win rates
- Tests you changed and why; anything you could not do
