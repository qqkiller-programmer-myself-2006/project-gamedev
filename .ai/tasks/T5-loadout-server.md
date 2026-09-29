# T5 — Server: pre-match loadout (Class, Race, Boons), Skill tree/Prestige and Gems (ADR-0013)

You are working on BEYOND THE WORLD'S END, a Godot 4.7 / GDScript co-op turn-based RPG with an authoritative server.
Read first: `CONTEXT.md`, `docs/testing.md`, `docs/adr/0012-...md` and
**`docs/adr/0013-pre-match-loadout-class-race-boons-prestige-gems.md` (the spec for this task)**.
ADR-0012 (attributes, Focus, enemy Energy, personal Gold) is already implemented on this branch — build on it.

## Files you may change

`src/match/**`, `src/core/**`, `src/server/**`, `src/net/**` (protocol additions only), `content/forest.json`, `tests/**`,
`tools/simulate.gd`, `docs/balance.md`, `CONTEXT.md`, `docs/adr/0010-...md` (status line only). Do NOT change `src/client/**`.

## What to build

1. **ProfileStore seam** (`src/core/profile_store.gd` + implementations): `MemoryProfileStore` (tests), `FileProfileStore`
   (JSON file in the server's user data dir; default for the local server) and `D1ProfileStore` (HTTP JSON to a Cloudflare
   Worker: `GET /profiles/<token>`, `PUT /profiles/<token>` with header `Authorization: Bearer <secret>`; URL and secret
   from server command-line args `--profile-url=` / `--profile-secret=` or env `PROFILE_URL` / `PROFILE_SECRET`).
   `MatchServer` receives the store from outside like the clock and rng. Saving is async and never blocks the Match.
   Profile shape: `{gems, races_owned[], class_trees{class: {node: level}}, prestige{class: n}, last_loadout{}}`.
2. **Identity**: the join/room command accepts `token` (32 hex chars). Missing token → a session-only profile (0 gems,
   nothing persisted). Load the profile on join; expose `profile` (gems, owned races, trees, prestige) in that player's
   room snapshot only.
3. **Room-phase commands** (rejected once the Match started): `set_loadout {class, race, boons[]}`, `buy_race {race}`,
   `tree_upgrade {class, node}`, `buy_prestige {class}`, `reset_tree {class}` with the costs, caps and unlock rules in the
   ADR; errors in the existing style (`not_enough_gems`, `locked`, `over_capacity`, ...). Loadout is visible to everyone in
   the room snapshot (class, race, boons per slot).
4. **Match start**: humans with a loadout start with that Class (no Classless), Race passives, Boons, tree bonuses
   (Stat Points → extra unspent attribute points; Vitality, Might, Precision, Swiftness, Reserves, Mastery) and Prestige
   bonuses. AI slots get classes from `party.ai_class_order` that are not already in the Party, a free race and no boons.
   With no loadout at all, behaviour is exactly today's Classless start (keep existing tests valid).
5. **Content** (`content/forest.json`): `meta.races`, `meta.boons`, `meta.class_tree` (7 nodes, 3–3–1 layout positions,
   per-level effects, costs), `meta.prestige` (cost 100, max 25, bonus), `meta.gems` (earn rates), `party.ai_class_order`,
   Class `description` + `recommended_stats` for the carousel. All numbers from the ADR tables.
6. **Enervation becomes a Boon** (remove the Rogue class passive; same effect when the Boon is equipped). Update Rogue tests
   so they equip the Boon where they test Enervation. New derived stat `status_resist` (chance to resist enemy statuses).
7. **Gems**: award at Match end per ADR §5 and at Class Encounter wins (Class Encounter now gives EXP + Gems when the
   character already has a Class); persist through the store. End-of-match summary includes gems earned per player.
8. Update `CONTEXT.md` per the ADR Consequences section.

## Rules you must keep

- Randomness only through `GameRng`, time only through the injected clock; tests only through `MatchServer`.
- Content numbers live in `content/forest.json`.

## How to verify (all must pass before you finish)

1. `bash scripts/run_tests.sh` → 0 failed.
2. New tests (`tests/match/test_loadout.gd`, `tests/match/test_meta_progression.gd`, `tests/core/test_profile_store.gd`):
   every command's happy path and errors; costs/caps; Prestige reset; Reset refund; match start applies class/race/boons/
   tree; AI class fill; Classless when no loadout; Enervation only with the Boon; gems awarded and saved; FileProfileStore
   round trip in a temp dir; D1ProfileStore builds the right requests (inject a fake HTTP sender — no real network in tests).
3. `"$GODOT" --headless --path . -s tools/simulate.gd -- --seeds=100 --humans=1,2` → within 70–97% for the default
   (no loadout) path, and add a `--loadout` mode where bots pick a class/race/boons; report both.

## Report (end your run with this, in English)

- Files changed, one line each; new commands and snapshot fields
- Test result line and simulate.gd win rates
- Tests you changed and why; anything you could not do
