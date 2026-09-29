# T11b — Story mode, part 2: server Story room, save/restore, home page wiring

Read `docs/adr/0014-offline-story-mode.md` (spec), `docs/adr/0013-*.md` (loadout), `CONTEXT.md`, and the part-1 files:
`content/story_mode.json`, `src/client/story/*.gd`, `tools/story_preview.gd`. Part 1 is merged; ADR-0012/0013 server work and
the new home page (`src/client/screens/title_screen.gd`, `src/client/home/`) are merged too.

## Server (src/match/**, tests/**)

1. `create_room` accepts `story: true` → a Story room: one session controls **all five** Party slots (no AI replacement), no
   Action window timeout (turns wait for the player), Path Voting with the single voter, Ready check passes when that player is
   Ready. Commands that act for a character take the acting slot from the current turn (or an explicit `slot` field where a
   command targets a character, e.g. `invest`, `equip`, `transfer_*`); reject acting for slots in non-story rooms as today.
2. `set_loadout` in a Story room accepts a `slot` so the player picks a Class for each of the five characters before starting.
3. **Save/restore**: `MatchServer` can export a Layer-start snapshot (seed, Layer index, route, each character's class, level, EXP,
   attributes, invested points, gear, HP, consumable, gold; Stash; Story Clues) and start a Story Match from such a snapshot.
   Emit an event at the start of each Layer so the client can save. Pure data (Dictionary) — the client writes it with StorySave.
4. Tests: Story room control of all slots, no timeout, loadout per slot, export → restore → same party/state, non-story rooms
   unchanged (Multiplayer behaviour identical). `simulate.gd --story` mode with a bot controlling all five; report win rate.

## Client

5. Home page: the Play panel gets **Story** (New / **Continue** when `StorySave.has_save()`) and **Multiplayer** (the existing
   Create room / Join room). Story → a small setup panel to pick a Class for each of Arin, Bram, Cora, Dain, Wren → starts
   `StoryLauncher` (offline, LocalConnection) with a Story room and starts the match; Continue restores from the save.
6. `StoryDirector` hooked into the match screen: prologue at start, chapter card per Layer, trigger scenes; saves via StorySave
   on the Layer-start event; clears the save on victory/defeat. When the player controls all five, the battle HUD shows whose
   turn it is (the acting character's name/class) and all Fight/Items/Focus actions go to that character.
7. Fix from part-1 QA: `ChapterCard` text is not centred (title/subtitle pushed right) — centre everything; and in
   `content/story_mode.json` Arin says "Arin, Bram, Cora, Dain—stay close" (addressing herself) — rewrite that line.
8. Multiplayer must work exactly as before (Create/Join, Playtest, `--auto`, browser `?auto=1`).

## Verify

- `bash scripts/run_tests.sh` → 0 failed (exact line). Run ONE Godot process at a time (low RAM).
- Screenshots (ui_preview or story_preview): home Play panel with Story/Multiplayer, class-pick panel, prologue in the match,
  a chapter card, a battle where the HUD shows the acting character. Scale 1.0 and 1.4.
Report in English: files changed, test line, win rate for --story, screenshot paths, anything not done.
