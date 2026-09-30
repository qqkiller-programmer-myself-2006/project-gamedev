# T20b — Forest enemies renamed, Layer 5 becomes a cave (#73 step 2, content + balance)

Read `AGENTS.md`, `CONTEXT.md`, `gh issue view 73`, `docs/design/balance.md`, `content/forest.json`, `content/story_mode.json`,
`assets/enemies/manifest.json` (frame data + `size_px` + variants), `tools/dev/simulate.gd`.

## Owner decisions (2026-09-29/30)
- Forest enemies take the names of the owner's art, same ids, same stats and behaviour:
  `grey_wolf` -> name "Wolf", sprite `wolf`; `masked_outlaw` -> "Thief", sprite `thief`; `stone_sentinel` -> "Golem",
  sprite `golem`; `forest_wisp` -> "Slime", sprite `slime`; `bramble_archer` -> "Goblin", sprite `goblin`. Update each
  `description` and any player-facing text that names them (combat group text, site hints, story/tutorial text in
  `content/story_mode.json`). Keep ids (fewer bugs, saves stay valid).
- `thornback_boar`: leave exactly as it is (owner will decide later). Boss (Elder Thornwarden): keep, the owner will send boss
  art; only move its fight into the cave (backdrop) — do not rename it.
- The last Layer (5) and the boss happen in a cave with 4 new enemies: `kobold` (sprite kobold, 32 px, fast spear skirmisher),
  `skeleton` (sprite skeleton, 32 px, sword+shield, resists physical a little), `giant_spider` (sprite giant_spider, 64 px,
  web attack that applies a slow/root-like existing status if one exists, else poison), `minotaur` (sprite minotaur, 64 px,
  heavy hitter, `charge_strongest`). Give each: name, description (1 line, English, ADR-0007), stats on the Layer-5 tier of
  the current forest enemies, behaviour from the existing set, Energy/special like other enemies (ADR-0012), rewards.

## Build (content + tests + docs only)
1. `content/forest.json`: renames + `sprite` field on the five forest enemies; four cave enemies; combat groups for layer 5
   only use cave enemies (2–3 per group, 4–5 groups, weights); forest groups end at layer 4 (adjust `layers` ranges so layers
   1–4 always have groups); cave combat `sites` for layer 5 ("Cave Mouth", "Bone Pit", "Spider Hollow" style names + hints);
   `journey.backdrops` = {"1":"forest","2":"forest","3":"forest","4":"forest","5":"cave"}; `boss.backdrop` = "cave".
   If the route generator reads sites by type only, add a `layers` filter to cave sites the same way groups have one — if that
   needs code, change only `src/match/rules/route_generator.gd` minimally and test it.
2. Story mode text that says the finale is in the forest -> the cave under the forest (keep it short).
3. Balance: `tools/dev/simulate.gd` default, `--loadout` and `--story` (100 seeds, humans 1 and 2) all within 70–92%; tune
   the cave enemies first. Record before/after in `docs/design/balance.md` (UTF-8!).
4. Tests: renamed names where tests pin text; layer 5 groups contain only cave enemies; every enemy with `sprite` names an
   id present in `assets/enemies/manifest.json`; backdrops cover layers 1–5.

## Rules
- Files: `content/**`, `docs/design/balance.md`, `tests/**`, and only if needed `src/match/rules/route_generator.gd`.
  Not `src/client/**` (another executor wires the sprites and backdrops in parallel, reading `sprite`, `journey.backdrops`,
  `boss.backdrop`).
- Write files as UTF-8 (no UTF-16). Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`
  -> exact line, 0 failed (baseline 285); simulate lines for every mode. ONE Godot process at a time.
- Report in English: renamed texts, cave enemy stats table, groups, win rates per mode, test line.
