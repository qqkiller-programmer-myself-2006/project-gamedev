# Final pre-PR review — 2026-09-30

Scope: committed code `5a84021..HEAD` (HEAD `b52673b`, including T27 dev jump and T28 #41-#43, which landed during the
review). It covers the restructure (#72), the P0 fixes (#62 stash, #63 story save trust, #64 D1 sender), #65-#71, the
Rogue→Assassin rename, hero and enemy art, backdrops, cave Layer 5 content, icons, `.ai/run-agent.ps1`, and the export presets.
This is a read-only review. Godot was not run. Every finding was traced in `git show HEAD:<path>`, and line numbers refer
to HEAD. Uncommitted work in other worktrees was not reviewed. Findings fixed since the 2026-09-29 reviews are not repeated.
Fixes that did not work, or only partly worked, are reported again and marked.

## Summary

| Severity | Count |
| --- | --- |
| P0 (crash / data loss / wrong result) | 0 |
| P1 (likely player-facing bug) | 3 |
| P2 (quality / risk / ADR drift) | 17 |
| **Total** | **20** (15 CONFIRMED, 5 PLAUSIBLE) |

### Checked and OK

- **Restructure (#72):** no stale `res://` or old-folder paths remain in `src/`, `tests/`, `tools/`, CI, README or guides. Every
  `.gd` has a `.gd.uid` and there are no orphan or duplicate UIDs. `main.tscn` and the `project.godot` main scene resolve.
  CI calls `tools/run_tests.sh` and `tools/ci/web_smoke.mjs`. `test_no_engine_randomness` points at `src/shared`/`src/profile`.
- **Exports:** all three presets keep `include_filter="content/*.json"`, so `content/story_mode.json` ships. `art_source/*` is
  excluded, and `art_source/.gdignore` also keeps it out of import. The assets that ship (`assets/heroes`, `assets/enemies`,
  `assets/backgrounds`, `assets/icons`, fonts) are loaded through `load()`, which is export-safe. No release export is missing
  code-referenced content or art. The only remaining question is the manifest JSON (F19, carried over from C21).
- **Art/content integrity:** every frame named in `assets/heroes/manifest.json` (5 classes) and `assets/enemies/manifest.json`
  (9 enemies, including variants) exists. Every `enemies.<id>.sprite` is in the manifest. `journey.backdrops` covers Layers 1-5
  and `boss.backdrop` is `cave`. Every item, recipe material, drop, story-outcome item, clue and class-site id resolves.
  Layer 5 combat sites and groups are cave-only.
- **#62:** `transfer_item` removes from the Stash through `remove_item` before it fills or swaps the slot. Combat Items now
  include the actor's Consumable slot.
- **#63:** the dedicated server refuses `create_room {story}` and `restore_story` (`allow_story`), and Story rooms never award
  or save Gems. `valid_story_save` agrees with the rules: Human +1 point on even levels, attributes rebuilt from
  class/race/boons/invested/gear, the Stash, gear and clues checked against content, and personal gold summing to `gold`.
  I found no legitimate save it would reject.
- **#64:** a D1 GET that is not 200 or 404 gives `_unavailable`, and such profiles are never saved. Tokens are lower-cased.
  The Worker upsert is guarded by version and has a migration note. Saves are async and coalesced per token.
- **#65/#71:** race and boon attributes apply before stats. Turn order uses initiative, then speed. A dodge blocks statuses and
  coating. Alert, Will of Thiacdemo, Critical Healing (ADR-0013), Daredevil, Kobold/Human/Dwarf/Lunaeia and enemy
  first-turn Energy are all implemented, each with a test. `run.gold` is derived, and no code writes to it.
- **#66:** `_pending_action` and the connect deadline are cleared on every close, replace and result. Stale-connection
  `closed` signals are ignored because the field is nulled before `close()`. Owned servers stop on title.
- **#67:** Merchant, Rest, Class offer and Story vote/read have no deadline in Story rooms. `class_choice` is remapped. The
  host slot replaces slot 0.
- **Rogue→Assassin:** the profile `class_trees`, `prestige` and `last_loadout`, plus `set_loadout {class: rogue}`, all migrate.
  No stale `rogue` ids remain.
- **T27 dev jump:** only the embedded Playtest server sets `allow_dev`, and it binds 127.0.0.1. The dedicated server rejects
  `dev_jump`.

## Findings

| id | sev | verdict | file:line | defect | failure scenario | suggested fix |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | P1 | CONFIRMED | `src/match/encounters/combat_encounter.gd:949-966`, `src/client/match/battle/battle_view.gd:504-505`, `src/client/match/battle/battle_token.gd:76-77` | The server's enemy view has no `sprite` key, and the client never looks up `enemies.<kind>.sprite` in content. Only `ui_preview` injects a `preview_enemy_sprites` map. | In every real Multiplayer, Playtest or Story fight, all enemies are drawn as the old code-drawn blocks. The #73 enemy art never appears outside the preview screenshots. | Add `"sprite": str(content.enemies[kind].sprite)` (and a variant) in `_make_enemy`/`_enemy_views`, or map kind→sprite in `battle_view` from the content it already loads. Remove the preview meta (see F13). Add a test that builds a token from a real `MatchHarness` snapshot. |
| F2 | P1 | CONFIRMED | `src/client/story/story_director.gd:49-67`, `src/match/match_run.gd:89` (`_begin_layer(1)` in `_init`) | `observe()` treats any first snapshot with `layer > 0` as a Continue. The first snapshot of a new Match already has `layer == 1`, so the prologue is marked shown without being queued, and `last_layer = 1` also skips the Chapter 1 card. `begin()` is never called. | New Story → no prologue and no "Chapter 1" card; the story starts at Chapter 2. "Start a new Match" in the same room behaves the same way, so the C13b fix turned into "never shows the prologue". On a real Continue at Layer N, the Chapter N card is skipped, and `merchant_first`/`rest_first`/`story_clue` replay (C13a is still partly open). | Tell the two cases apart explicitly: a restore marks the director, for example with `ClientApp._story_restore` non-empty or a `restored` flag in the snapshot. Otherwise queue the prologue plus Chapter 1. Persist the `shown` keys in the story save. Fix `test_story_director.gd:70`, which uses the unrealistic `layer: 0`. |
| F3 | P1 | CONFIRMED (visible once F1 is fixed) | `src/client/match/battle/battle_token.gd:151,162,208`, `assets/enemies/manifest.json` (`"die"`) | Tokens request the `dead` animation. Enemy manifests name it `die`, so `frames("dead")` returns `[]`. `_draw_figure` then falls back to the block figure for one frame, and `_process` switches to the looping idle animation. | Defeated enemies keep standing and bobbing in idle, only greyed out, instead of playing their death frames. | In `SpriteSet.frames`, alias `dead`→`die` for enemies, or rename the manifest key. Assert in `test_enemy_sprite_set` that `frames("dead")` is non-empty. |
| F4 | P2 | CONFIRMED | `src/match/room.gd:118-128,243`, `src/client/story/story_launcher.gd:10`, `src/match/match_server.gd:50`, `tools/dev/simulate.gd:74-77`, `tests/match/test_story_room.gd:205` | The "lead uses the profile Race/Boons" change (S21/C25) has no effect. (a) `StoryLauncher` builds `MatchServer` with the default `MemoryProfileStore`, so the story profile is always empty (Human, no boons). (b) `_set_loadout` writes `profile.last_loadout` for every Story slot, so slot 4's Human/[] loadout overwrites the host's before `start_match` reads it. The test works around this by resetting `last_loadout` after the `set_loadout` calls. The simulator's slot-0 Elf+Bunny is silently replaced by Human/[]. | ADR-0014 "Loadout" is not met: owned races and boons never apply in Story. If a real profile is wired in later, `valid_story_save` (`match_run.gd:673-682`) ignores the `stat_points` tree bonus and would reject, then delete, that player's saves. | Only update `last_loadout` when `slot == host_slot` or outside Story. Pass a read-only snapshot of the local profile into `StoryLauncher`, or state "no meta in Story" in ADR-0014. If trees ever apply, include `_tree_level(stat_points)` in the save point check. |
| F5 | P2 | CONFIRMED | `src/profile/d1_profile_store.gd:30-42`, `src/profile/http_profile_sender.gd:44-50` | The version sent is `max(loaded, _versions[token]) + 1`, so a single server process always outbids itself. The Worker's version check only catches writes from a different process. A 409 is retried three more times with the same body and then dropped. | The same token in two sessions (two tabs) on one server: A buys Dwarf (v6), then B's Match-end save (v7, built from the older profile) is accepted and Dwarf is lost. S11a is still open. | Keep the loaded version per session as the base, send `base+1`, and on 409 reload and merge, or report "profile changed elsewhere". Do not retry 4xx. |
| F6 | P2 | CONFIRMED (blocking) / PLAUSIBLE (impact) | `src/profile/d1_profile_store.gd:17`, `src/profile/http_profile_sender.gd:15-16`, `src/match/match_server.gd:271-281` | `load_profile` does a synchronous HTTPClient GET on the server's main loop, which can take up to 3 s plus DNS/TLS on every create or join. | While the Worker is slow, every room freezes on each join. Action and vote deadlines keep running on `SystemClock`, so players lose turns. Repeated joins can stall the server. | Load profiles asynchronously and admit the session as "profile loading", or at least cap the GET at about 1 s and cache per token. |
| F7 | P2 | PLAUSIBLE | `src/profile/http_profile_sender.gd:25-41` | `stop()` makes the worker return at once, discarding `_pending` and aborting an in-flight PUT. | A server restart or redeploy just after a Match ends loses that Match's Gems and progress. | On stop, drain `_pending` with a short total budget (for example 2 s) before joining. |
| F8 | P2 | CONFIRMED | `src/match/match_server.gd:280-281`, `src/client/lobby/lobby_screen.gd:26-36`, `src/client/match/match_screen.gd:561` | The `profile_unavailable` event is sent in the first update after create/join, when the client is on the Lobby screen. `LobbyScreen.show_events` ignores it, and only `MatchScreen` handles it. | When D1 is down, players are never told that "progress will not be saved", which is the point of #64. | Handle it in `LobbyScreen.show_events` (toast), or have `ClientApp._on_update` toast it for any screen. |
| F9 | P2 | CONFIRMED | `src/client/client_app.gd:545-549` | While a tutorial hint is open, `_unhandled_key_input` swallows every key except H. Battle, vote and camp hotkeys and Esc all do nothing, and nothing tells the player why. | A first-time Multiplayer player gets the "combat" tip on their first turn. F/I/1-9 do nothing, and the 15 s action window can run out into an auto-Defend. | Only reserve H, and let other keys through (or close the hint and pass the key on). Or show "[H] to continue" in the tip. |
| F10 | P2 | CONFIRMED (Multiplayer only) | `src/client/match/camp/camp_view.gd:214-220`, `src/client/match/match_screen.gd:155-167` | The C3 fix covers typing, but the search `LineEdit` still has no `focus_id`. Any external snapshot change (another player buys, readies or invests) rebuilds the camp and moves focus to Ready. The LineEdit guard in `handle_key` then no longer applies. | While the player types "sword" in a Multiplayer Merchant and a teammate buys something, the remaining letters go to hotkeys: R sends Ready and digits buy items. | Set `focus_id` on both search boxes (and restore the caret), or skip camp rebuilds while a LineEdit has focus. |
| F11 | P2 | CONFIRMED | `src/client/match/camp/camp_view.gd:51-53` | The camp's `BattleBackdrop` never gets `set_backdrop()`, so it always draws the code-drawn forest. | A Merchant or Rest at Layer 5 (the cave) shows the forest backdrop. | Call `set_backdrop(journey.backdrops[layer])` in `build()`, as `battle_view` does. |
| F12 | P2 | CONFIRMED | `src/client/match/battle/battle_view.gd:190-192` | `build()` opens and parses the whole `forest.json` on every battle rebuild (every snapshot change) just to find the backdrop name. | Frame hitches on every action in the web build. | Parse once in `setup()` (camp_view already does), or better, have the server put the `backdrop` key in the encounter view. |
| F13 | P2 | CONFIRMED | `tools/dev/ui_preview.gd:64-66` | The preview injects its own enemy→sprite and backdrop maps. This hid F1, and the map is stale: `thornback_boar→golem` and `elder_thornwarden→minotaur` disagree with content, where both have no sprite (#75). | Preview screenshots show art the real game never shows, so QA and screenshot review pass. | Remove both metas once F1 is fixed so the preview renders what players see. |
| F14 | P2 | CONFIRMED | `content/story_mode.json:59-62` | The `party_defeated` epilogue now says "The cave beneath the Forest closes around the fallen Party" and "reach the Guardian in the cave". | A wipe in forest Layers 1-4 plays a cave epilogue. | Keep the defeat text neutral, or split it into `party_defeated` and `party_defeated_cave` by layer. |
| F15 | P2 | CONFIRMED | `src/client/match/camp/camp_view.gd:595-690`, `src/client/match/story_panel.gd:26,48,60`, `src/client/match/vote_panel.gd:26`, `src/client/ui/ui_text.gd:49`, `docs/adr/0010-rogue-class-and-dot-status-effects.md:1` | ADR-0007 drift continues (C17 is partly open). New UI text is hard-coded: the item and abilities popups ("Quantity", "Bonuses", "This character has no Class Skills.", "Close [Esc]", "Transfer from %s"), the Story panel and vote copy. `story_offline_only` tells players to play "over Local Network", which does not exist. The ADR-0010 rename note sits above the YAML front matter, which breaks it. | Text drifts and cannot be localised. The error message is misleading. ADR tooling or a parser misreads the status. | Move the strings into `UiText.LABELS`/`WHY`, reword `story_offline_only`, and move the note below the front matter. |
| F16 | P2 | CONFIRMED (offline only) | `src/match/match_run.gd:639,664,671`, `src/match/room.gd:132-137` | Save validation checks items with a dotted `get_value("items.%s")`, so `herb.price` passes (the S15 pattern). `route` option contents, `hp`/`max_hp` and `consumable.count` are not checked, and `restore_story` still calls `start_match()` before the restore can fail. | A hand-edited local save gets past validation, then fails mid-restore. The Story room is left `IN_MATCH` with a half-built run. This only affects the offline player, not security, because Story is offline-only since #63. | Use `forest.get_dict("items").has(id)`. Validate the route shape (arrays of `{type in ENCOUNTER_TYPES, ...}`) and numeric hp. Build and restore the `MatchRun` before switching the room state. |
| F17 | P2 | PLAUSIBLE | `export_presets.cfg:10,45,78`, `deploy/prepare.sh:9-16`, `assets/icons/_contact.png` | `exclude_filter` does not exclude `deploy/*`. After `prepare.sh`, `deploy/web/*.png` (the web shell icons) are imported and packed into the next export. The icon contact sheet (41 KB) and the 3.3 MB/2.1 MB PNG backdrops also ship unoptimised. | Web and PC packages grow, and a local re-export packs an old build's files. This was partly pre-existing, but the restructure touched the filters. | Add `deploy/*` to every `exclude_filter` (or `deploy/.gdignore`), move `_contact.png` to `art_source/`, and consider lossy import for the backdrops. |
| F18 | P2 | PLAUSIBLE | `.ai/run-agent.ps1:30,105-122,158` | The stall detector counts any file change in `-Worktree` as activity. When the worktree is the repo that holds the runner, the status JSON rewritten every 30 s into `.ai/logs` resets the idle timer. The final status also records `$Agent`, not the fallback agent that actually ran. | Running the runner on the integration worktree itself means a hung agent is never flagged `stalled`. The logs then blame the wrong agent. | Exclude `.ai[\\/]logs` in the path filter. Write `agent = $attempts[-1].agent` in the final status. |
| F19 | P2 | PLAUSIBLE (carried over from C21) | `export_presets.cfg:9,44,77`, `src/client/match/battle/sprite_set.gd:6,9,127-147` | `assets/heroes/manifest.json` and, new in this range, `assets/enemies/manifest.json` are read with `FileAccess`, and `include_filter` lists only `content/*.json`. Godot 4 most likely exports `.json` as a JSON resource under `all_resources`, but no export has been checked. | If they are left out, exported builds draw no hero or enemy sprites, and the home screen shows no party. | Add `assets/*/manifest.json` to `include_filter`, or check once in the #54 export pass (unzip the `.pck` or run `--export-pack` and list its contents). |
| F20 | P2 | CONFIRMED | `tests/client/test_story_director.gd:66-83`, `tests/match/test_story_room.gd:55-96`, `tests/client/test_enemy_sprite_set.gd`, `tests/profile/test_profile_store.gd` | Test gaps that let F1-F3 and F5-F7 through. Director tests use `layer: 0`, which never occurs. Nothing checks that a real server snapshot yields enemy sprites or a `dead` frame. Story restore round-trips only at Layers 1-2, with no level-ups or invested points, so the Human point rule in `valid_story_save` is never exercised on real data. There is no test for draining the sender on stop or for a 409 in the same process. | Regressions in these paths pass CI. | Add: a director test fed a real `MatchHarness` story snapshot; a battle-token-from-snapshot test; a save round-trip after level 3+ Human with invested points and gear; a D1 test with two sessions on the same token. |

### Post-review disposition

- **F4 (Story lead profile): not a defect under the accepted ADR-0014 policy.** ADR-0014 specifies an isolated in-memory Story profile with Human and no Boons or class-tree meta, which the current `StoryLauncher` and `Room` implement. The earlier review text calling for the lead's online Race/Boons conflicts with that decision. Keep the no-meta behavior unless the owner accepts a new ADR; if changed, specify local profile sourcing and save validation first.
- **F5 (same-token sessions): addressed in the current profile store.** Saves advance each session's loaded version independently; a 409 marks that session stale and stops further writes rather than retrying old data over a newer profile. The player receives the existing save-failure event.
- **F6 (blocking profile GET): partially addressed.** `HttpProfileSender` caps GET at one second. Loading is still synchronous on the server main loop, so joins may pause for up to that bound; asynchronous admission and per-token caching remain possible follow-ups.
- **F7 (shutdown save loss): addressed.** `HttpProfileSender.stop()` drains queued/in-flight saves within a two-second total budget before joining its worker.
- **F8 (unseen save notice): addressed.** `LobbyScreen.show_events()` displays `profile_unavailable` as a toast.
- **F17 (deployment files in exports): addressed.** All three presets exclude `deploy/*`. `_contact.png` and backdrop compression were not changed in this follow-up.
- **F19 (manifest shipping): verified with a real Web pack.** Godot 4.7.2 exported `.tmp-t76-web.pck`; byte inspection found both `assets/heroes/manifest.json` and `assets/enemies/manifest.json`, and no `deploy/` path. The temporary pack was removed after inspection.

Notes (not scored):
- T27 dev jump grants levels and Gold and can jump to the Boss. The embedded Playtest server then saves real Gems to the
  developer's `user://profiles` (or to D1 if `PROFILE_URL` is set in the environment). This is dev only; consider skipping
  profile saves when `allow_dev` is set.
- Story enemies are capped at 1 Energy (`rules.story_enemy_energy_max`), so their 2-3 Energy specials never fire in Story.
  This is intentional and documented (ADR-0014, balance.md). It is listed here so the owner knows Story fights have no enemy
  specials.
- C19/C20 (preview tools writing to the real `user://`) and C22 (web save tombstone) were not re-verified. Treat them as still
  open.

## Development plan

| order | task | findings | owner | size | issue |
| --- | --- | --- | --- | --- | --- |
| 1 | Enemy sprites in real games: send `sprite` from the server (or map it in the client from content), alias `dead`→`die`, remove the preview metas, add token-from-snapshot and dead-frame tests | F1, F3, F13 | server + client + tools | S | reopen #73 |
| 2 | Story director: tell a new run from a Continue, queue prologue + Chapter 1 on new runs, the Chapter N card on Continue, persist `shown` in the save, realistic director tests | F2, F20 (director part) | client | S | reopen #67 |
| 3 | Story lead profile: `last_loadout` only for the host slot, give Story a read-only local profile or amend ADR-0014, include `stat_points` in save validation if trees apply, fix the simulator comment | F4 | server + client + docs | S | new issue (follow-up to #67 / #58) |
| 4 | Profile store hardening: per-session base version and 409 reload, no 4xx retry, async/short-timeout GET, drain on stop, `profile_unavailable` shown on the Lobby | F5, F6, F7, F8 | server + client | M | #55 (and #64 follow-up) |
| 5 | Input and camp polish: hints do not swallow hotkeys, `focus_id` on camp searches, camp backdrop per layer, parse content once in `battle_view` | F9, F10, F11, F12 | client | S | #69 / #68 follow-up (new issue) |
| 6 | Text and content: move new strings to `UiText`, reword `story_offline_only`, neutral defeat epilogue, ADR-0010 front matter | F14, F15 | client + content + docs | XS | #70 follow-up |
| 7 | Offline save robustness: exact-key item checks, route and hp shape, restore before switching room state, level-3+ round-trip test | F16, F20 (save part) | server | S | #63 follow-up |
| 8 | Export check for #54: add `deploy/*` exclude and `assets/*/manifest.json` include, move `_contact.png`, list the `.pck` of a real Windows/Web export | F17, F19 | tools/build | S | #54 |
| 9 | Runner: ignore `.ai/logs` in the stall detector, report the agent that actually ran | F18 | tools | XS | new issue (tooling) |

Order: 1 and 2 are the player-facing bugs, and both are small and must ship before the 2026-10-02 build. 3 and 4 restore
ADR-0014 and the ADR-0013 persistence guarantees before D1 goes live (#55). 5-7 are polish and robustness. 8 gates the
final export in #54. 9 is internal tooling and can wait.
