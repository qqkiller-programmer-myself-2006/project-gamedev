# T14 — P0: consumables duplicate on transfer (#62) + story save trust boundary (#63)

Read first: `AGENTS.md`, `CONTEXT.md`, `docs/adr/0012-*.md`, `docs/adr/0014-offline-story-mode.md`,
`docs/review/2026-09-29-server-review.md` (findings S1, S2, S8, S12, S13) and the two GitHub issues:
`gh issue view 62` and `gh issue view 63` (repo qqkiller-programmer-myself-2006/project-gamedev).

## Part A — #62 (server, `src/match/**`)
1. `MatchRun.add_item(item, -1)` is a no-op (`src/match/match_run.gd`, `add_item` returns for `count <= 0`), so
   `transfer_item` never takes the item out of the Stash (S1) and the swap branch never removes the new item (S12).
   Add `remove_item(item: String, count: int = 1) -> bool` (false and no change when the Stash has fewer; erase the key at 0)
   and use it in every path of `transfer_item`. Grep for any other `add_item(..., -N)` call and fix it the same way.
2. S8: combat `choices.items` (`src/match/encounters/combat_encounter.gd`, around the `choices` builder) must also list the
   acting character's Consumable slot item, and using an item must take it from the slot first, then the Stash. Keep the
   client contract the same shape (item id -> count); add a field only if needed and document it in the ADR-0012 notes.
3. Tests (`tests/match/`): Stash count after transfer to an empty slot, to a slot holding the same item, and a swap
   (old stack returns, new item leaves); transfer with 0 in Stash is rejected; slot item appears in combat Items and is
   consumed from the slot.

## Part B — #63 (server trust boundary + client message)
1. S2: the online server must not open story rooms. `MatchServer` gets a flag (e.g. `allow_story := false`, set true only by
   the in-process LocalConnection/story launcher path — see `src/client/story/story_launcher.gd` and `client_app.gd`).
   With the flag off, `create_room {story: true}` and `restore_story` return a new error code `story_offline_only`.
   `GameServer` (`src/server/game_server.gd`) never sets it, including the embedded Playtest server.
2. Story rooms never award Gems (`award_gems` is a no-op when the run is a story run) and never write the profile store.
3. S13: `valid_story_save` (`src/match/match_run.gd`) checks every field: version, types, ranges (gold >= 0 and sane cap,
   levels within the content max, gear/consumable ids exist in content, attribute totals consistent with level),
   `gems_earned` length == party size, clue types, required character keys. Anything else -> `invalid_save`.
4. C8/C26 (client): when restore fails, the story screen shows the error text from `ui_text.gd` and returns to the Story
   menu instead of hanging. Add text for `story_offline_only` and `invalid_save` to `ui_text.gd`.
5. Tests: forged save (extra gold, wrong gems length, unknown item id, missing key) is rejected; online-style MatchServer
   refuses story create/restore; a valid save still restores (keep `tests/match/test_story_room.gd` green).

## Rules
- Game logic stays in `MatchServer`/`MatchRun` (ADR-0001/0008). Only `GameRng`/injected clock. No new third-party code.
- Commit in small steps on this branch with messages like `fix: stash loses the item on transfer (#62)`, each ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash scripts/run_tests.sh` -> paste the exact summary
  line (must be 0 failed). After adding a `class_name`, run `"$GODOT" --headless --path . --import` once.
  ONE Godot process at a time (low RAM). Do not run the game window.
- Files you may change: `src/match/**`, `src/client/story/**`, `src/client/client_app.gd` (story launcher wiring only),
  `src/client/ui/ui_text.gd` (new texts only), `src/server/game_server.gd`, `tests/**`, `docs/adr/0012-*.md`, `docs/adr/0014-*.md`.
- Report in English: what changed per finding, new error codes, test summary line, commit hashes.
