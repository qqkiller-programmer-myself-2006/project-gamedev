# Plan: simpler folder structure (owner request 2026-09-29)

Goal: a new maintainer can find any file by guessing its folder. One place per kind of thing, folders named after what the
player sees (client) or the rule they own (server), no duplicates, no junk at the root. **No behaviour changes.**

## What is wrong today
| Problem | Where |
| --- | --- |
| 340 of the 368 files in `docs/` are three identical copies of old agent skills (`docs/.agents/skills`, `docs/.aider-desk/skills`, `docs/.claude/skills`). Newer copies live in `~/.claude/skills`. | `docs/` |
| Loose files at the root: `hello_world.txt` (connection test), `checkpoint.md` (planner notes) | root |
| `scripts/` holds one file; `tools/` mixes Godot scripts, Python and Node | `scripts/`, `tools/` |
| `src/core` mixes three things: determinism helpers (RNG, clocks), the content loader, and profile storage (4 stores + HTTP sender) | `src/core` |
| Client folders do not match screens: `camp_view` is in `battle/`, `settings_panel` in `screens/`, the title backdrop in `home/`, the character setup alone in `setup/`, combat/merchant panels in `panels/` away from the screen that shows them | `src/client` |
| Five loose rule helpers next to the match server | `src/match` |
| Raw art sheets live inside `assets/`, so Godot imports and exports them | `assets/characters/source` |
| Tests do not mirror `src` (`test_battle_view_data` is under `tests/match`, story client tests under `tests/client`, profile tests under `tests/core`) | `tests/` |
| Nine loose docs with no grouping | `docs/*.md` |

## Target tree
```
project.godot  export_presets.cfg  README.md  AGENTS.md  CLAUDE.md  CONTEXT.md
assets/                      runtime art only (imported by Godot)
  fonts/
  heroes/<class>/            was assets/characters/<class>; manifest.json stays beside them
  enemies/<id>/              new (art work after this plan)
  backgrounds/               new
  icons/                     new (#61)
art_source/                  raw sheets, never imported (.gdignore): heroes/ enemies/ backgrounds/
content/                     forest.json, story_mode.json (unchanged)
src/
  app/                       main.tscn, main.gd, launch_options.gd (unchanged)
  shared/                    game_rng, system_clock, manual_clock, forest_content (used by server and client)
  profile/                   profile_store, memory_/file_/d1_profile_store, http_profile_sender
  match/                     authoritative rules (name kept: MatchServer is a domain term, ADR-0001/0008)
    match_server.gd room.gd room_codes.gd match_run.gd
    rules/                   attributes, status_book, enemy_groups, route_generator, path_vote
    encounters/  ai/         (unchanged)
  net/                       (unchanged)
  server/                    game_server.gd (unchanged)
  client/
    client_app.gd
    ui/                      ui_kit, ui_text, confirm_dialog, sound_bank, client_settings (+ icons later)
    title/                   title_screen, home_backdrop, settings_panel
    lobby/                   lobby_screen, character_setup
    match/                   match_screen, info_panel, vote_panel, summary_panel, class_panel, story_panel
      battle/                battle_view, battle_token, battle_backdrop, sprite_set, combat_panel
      camp/                  camp_view, merchant_panel
    story/                   (unchanged)
tests/                       mirrors src/: shared/ profile/ match/ net/ client/ regression/ support/ + run_tests.gd, test_case.gd
tools/
  run_tests.sh               was scripts/run_tests.sh
  dev/                       simulate.gd, ui_preview.gd, story_preview.gd, pc_smoke_client.gd
  art/                       slice_character_sheet.py (+ make_icons.py later)
  ci/                        web_smoke.mjs
deploy/                      unchanged
docs/
  README.md                  index: one line per doc
  design/                    prd, balance, ui-style, accessibility
  guides/                    running, staging, testing, web
  adr/ agents/ plans/ review/ references/ screenshots/
.ai/                         executor runner, task specs, checkpoint.md (moved from root)
.claude/agents/              subagent definitions
```

## Why this is safe in Godot
- 69 scripts use `class_name`; those names are global, so code that uses the class does not care where the file is.
- Only ~35 literal `res://` paths exist (tests' directory lists, `main.tscn`, `project.godot` main scene, sprite/portrait roots,
  font path, content path, preview tools). Every one is listed by `git grep -n "res://"` and gets updated.
- Every script has a `.uid` file: it moves with its script (`git mv a.gd b.gd` and `git mv a.gd.uid b.gd.uid`), so `.tscn`
  uid references keep working. Asset `.import` files move with their asset, then `godot --headless --import` refreshes them.
- `export_presets.cfg` excludes `tests/*, tools/*, docs/*, build/*`; add `art_source/*` too (and `.gdignore` keeps it out).

## Order (one commit per step, tests green after every step)
1. Freeze: no other executor running; all branches merged (done: #59, #62, #63, #64).
2. Delete `docs/.agents`, `docs/.aider-desk`, `docs/.claude` (duplicate skills), `hello_world.txt`; move `checkpoint.md` to `.ai/`.
3. `scripts/run_tests.sh` → `tools/run_tests.sh`; split `tools/` into `dev/ art/ ci/`; update CI, README, docs, agents.
4. `src/core` → `src/shared` + `src/profile`; `src/match` loose helpers → `src/match/rules/`.
5. `src/client` regrouped by screen as in the tree.
6. `tests/` mirror `src/`.
7. `assets/characters` → `assets/heroes`; raw sheets → `art_source/heroes` with `.gdignore`.
8. `docs/` grouped + `docs/README.md` index; fix every link.
9. Verify (below), update `AGENTS.md`/`CONTEXT.md` "where things live", README tree.

## Verify (all must pass before merge)
- `git grep` for every old path (outside `docs/review`, `.ai/tasks`, `.ai/checkpoint.md` history) returns nothing.
- `godot --headless --path . --import` has no errors; `bash tools/run_tests.sh` → same count as before, 0 failed
  (includes the compile-every-script test and the no-engine-randomness scan).
- `tools/dev/ui_preview.gd` produces every screenshot; `tools/dev/simulate.gd --seeds=10` runs.
- The game opens (`--dev --playtest`) and a Playtest match starts; export check: `--export-release "Windows"` if templates exist.

## After this
Art work (owner decisions 2026-09-29): new hero sheets for Archer/Mage/Swordsman/Guardian + Assassin (Rogue renamed to
Assassin); forest enemies renamed to match the art (Grey Wolf→Wolf, Masked Outlaw→Thief, Stone Sentinel→Golem,
Forest Wisp→Slime, Bramble Archer→Goblin, same stats); the last Layer + boss move into a cave with Kobold, Minotaur,
Skeleton, Giant Spider; forest and cave battle backgrounds.
