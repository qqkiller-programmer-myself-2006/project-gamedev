# T17 — Restructure folders and files (#72)

You are the `repo-restructurer`: read `.claude/agents/repo-restructurer.md` and follow its rules exactly. Then read the plan
`docs/plans/2026-09-29-restructure.md` and do steps 2–9 in order, one commit per step. Issue: `gh issue view 72`.

Baseline before you move anything: run the full tests and write the exact summary line in your report (expected
`281 passed, 0 failed`). Every step must end with the same count.

Details the plan leaves open (decided — do not change):
- Step 2: delete the directories `docs/.agents`, `docs/.aider-desk`, `docs/.claude` and the file `hello_world.txt`;
  `git mv checkpoint.md .ai/checkpoint.md`. `art_source/` already exists with `.gdignore` and the owner's new sheets — keep them.
- Step 3: `git mv scripts/run_tests.sh tools/run_tests.sh` and make it `cd "$(dirname "$0")/.."` still reach the repo root;
  `tools/dev/{simulate,ui_preview,story_preview,pc_smoke_client}.gd`, `tools/art/slice_character_sheet.py`,
  `tools/ci/web_smoke.mjs`. Update `.github/workflows/*.yml`, `.ai/run-agent.ps1` (if it names the script), every
  `.claude/agents/*.md`, `AGENTS.md`, `README.md`, `docs/`. Add `art_source/*` to every `exclude_filter` in `export_presets.cfg`.
- Step 4: `src/shared/`: game_rng, system_clock, manual_clock, forest_content. `src/profile/`: profile_store,
  memory_profile_store, file_profile_store, d1_profile_store, http_profile_sender. `src/match/rules/`: attributes,
  status_book, enemy_groups, route_generator, path_vote. Update `test_no_engine_randomness.gd` constants
  (GAME_LOGIC_DIRS must cover `res://src/match`, `res://src/shared`, `res://src/profile`; the RNG/clock/HTTP exemptions point
  at the new files).
- Step 5 (client), exact mapping:
  - `src/client/ui/`: ui_kit, ui_text, confirm_dialog, sound_bank, client_settings (already there)
  - `src/client/title/`: screens/title_screen, home/home_backdrop, screens/settings_panel
  - `src/client/lobby/`: screens/lobby_screen, setup/character_setup
  - `src/client/match/`: screens/match_screen, panels/{info,vote,summary,class,story}_panel
  - `src/client/match/battle/`: battle/{battle_view,battle_token,battle_backdrop,sprite_set}, panels/combat_panel
  - `src/client/match/camp/`: battle/camp_view, panels/merchant_panel
  - `src/client/story/` and `src/client/client_app.gd` stay. Remove the emptied folders.
- Step 6 (tests mirror src): `tests/shared/` (test_game_rng, test_no_engine_randomness), `tests/profile/`
  (test_profile_store + any http/d1 profile tests), `tests/client/` (story tests, test_ui_contrast, test_battle_view_data),
  `tests/match/` (the rest), `tests/net/`, `tests/regression/`, `tests/support/`, and `test_scripts_compile.gd` goes to
  `tests/` root. `tests/run_tests.gd` finds tests recursively — check it still finds every file (same count).
- Step 7: `git mv assets/characters assets/heroes` (with every `.import`), then `git mv assets/heroes/source/*`
  to `art_source/heroes/` (the `.jpg.import` files next to them are deleted, since art_source is not imported). Update
  `sprite_set.gd`, `character_setup.gd`, `dialogue_panel.gd`, `home_backdrop.gd`, `story_director.gd`, tools, tests.
- Step 8: `docs/design/`: prd, balance, ui-style, accessibility. `docs/guides/`: running, staging, testing, web.
  New `docs/README.md` index (one line per doc/folder). Fix every link to moved docs across the repo.
- Step 9: add a short "Where things live" section (the tree from the plan, 1 line per folder) to `AGENTS.md` and README;
  update `CONTEXT.md` only where it names paths.

Do not touch `content/*.json`, `deploy/**` code, or any `.gd` logic beyond path strings. Another executor is creating new files
under `assets/enemies/`, `assets/backgrounds/`, `tools/art/slice_enemy_sheet.py` on a parallel branch — do not create those.

Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
