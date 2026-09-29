# T19 — Hero art v2 for all five classes; Rogue renamed Assassin (#74)

Read `AGENTS.md` ("Where things live"), `gh issue view 74`, `docs/design/ui-style.md`, `src/client/match/battle/sprite_set.gd`,
`assets/heroes/manifest.json`, `tools/art/slice_character_sheet.py`. Look at every source sheet yourself.

## Part A — slice the new sheets
Sources (committed; never edit): `art_source/heroes/{archer,assassin,guardian,mage,swordsman}_sheet_v2.webp` (1536x1024).
Old v1 sheets (`art_source/heroes/*_sheet.jpg`) are replaced — keep the files, stop using them.
Template: big art top-left; rows with 4 direction groups (Down, Left, Right, Up) for the first row (idle; the Archer sheet labels
it "Player"), Idle, Walk, Run; a full-width **Attack** row (frames with bow/slash/magic effects that belong to the frame; the
Swordsman row is grouped Down/Left/Right/Up); Jump (3), Hurt (3–4), Dead (3); boxed Weapon, In-game example (ignore), a row of
skill icons with Thai captions, large splash art bottom-right. Positions differ per sheet: detect them (background mask +
connected components + row grouping); do not hard-code one sheet's pixels.

1. Update `tools/art/slice_character_sheet.py` (its `ROOT`/`SOURCE` still point at the pre-restructure paths — fix them:
   `ROOT = Path(__file__).resolve().parents[2]`, sources in `art_source/heroes/`) to slice the v2 template for all five
   classes into `assets/heroes/<class>/` using the SAME output file names and manifest keys the game already reads
   (idle/walk/run/attack/hurt/dead frame lists per direction as today, `portrait.png`, weapon, skill icons, splash).
   Battle uses the Right-facing frames for the party; keep that working. Add `jump` if cheap; unused keys are fine.
2. New class folders: `assets/heroes/guardian/`, `assets/heroes/assassin/`. Commit `.import` files after
   `"$GODOT" --headless --path . --import`.
3. Review contact sheets (`build/hero_contact/<class>.png`, not committed) yourself: transparency clean, no label text, weapons
   and effects not cut, feet on one baseline, frames in order.

## Part B — Rogue becomes Assassin (owner decision)
- Class id `rogue` -> `assassin` everywhere: `content/forest.json` (class, skills/tree keys that contain the id, texts),
  `src/**`, `tests/**` (rename `tests/match/test_rogue.gd` -> `test_assassin.gd` with its `.uid`), `tools/dev/*`.
  Player-facing name "Assassin". Keep skill ids unless they contain "rogue".
- Old data: `ProfileStore.normalize` maps any `rogue` key (class tree, prestige, last class) to `assassin`; loadout/join
  commands that still say `rogue` are accepted as `assassin` for one release. Add a test for both.
- Update ADR-0010 with a one-line note at the top ("Renamed Assassin on 2026-09-29, #74") and CONTEXT.md if it names Rogue.

## Part C — use the art
- Guardian and Assassin now have sprites: battle tokens, setup/class picker portraits, title backdrop (it may show 3–5 heroes;
  keep the campfire composition), story dialogue portraits by class. No class falls back to the blocky placeholder any more.

## Rules
- Commit per part (`feat: hero sheets v2 sliced (#74)`, `refactor: Rogue renamed Assassin (#74)`, `feat: Guardian and
  Assassin sprites in game (#74)`), explicit `git add`, messages ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  You MAY commit.
- Do not touch `assets/enemies/**`, `assets/backgrounds/**`, `tools/art/slice_enemy_sheet.py` (another executor creates them).
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
  (baseline 281); windowed `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --out=build/t19` and look at the
  title, setup and combat shots. ONE Godot process at a time.
- Report in English: per class frame counts, problems, rename touch list, test line, commits.
