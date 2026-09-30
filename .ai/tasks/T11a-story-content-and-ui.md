# T11a — Story mode, part 1: story script, dialogue UI, offline launcher, save file (new files only)

You are working on BEYOND THE WORLD'S END (Godot 4.7 / GDScript). Read first: `CONTEXT.md`, `docs/adr/0006-*.md` (Wren),
**`docs/adr/0014-offline-story-mode.md` (the spec)**, `content/forest.json` sections `party`, `story`, `ending`, `boss`,
`src/net/local_connection.gd` and `tools/ui_preview.gd` (how an in-process `MatchServer` + `LocalConnection` is built today).

Other agents are editing `src/match/**`, `src/server/**`, `src/client/screens/**`, `src/client/battle/**`,
`src/client/client_app.gd` and `src/app/**` right now. **Create new files only**; do not modify existing files except
`src/client/ui/ui_text.gd` (append only). Wiring into the home page and server rules comes in a later task (T11b).

## Build

1. **`content/story_mode.json`** — the story script, English, in the tone of `content/forest.json`'s existing story text:
   - `prologue`: 6–10 lines introducing the siblings Arin, Bram, Cora, Dain searching for their father, and Wren (the father's
     former apprentice who came back alone and cannot remember what happened after leaving the Forest).
   - `chapters`: one card per Layer 1–5 (`title`, `subtitle`) plus one for the Guardian Boss.
   - `scenes` keyed by trigger: `first_combat_won`, `class_gained`, `story_clue`, `merchant_first`, `rest_first`,
     `before_boss`, `boss_won` (epilogue), `party_defeated`. Each scene = list of lines `{speaker, text, mood}`
     (`speaker` ∈ arin, bram, cora, dain, wren, narrator). 3–8 lines each. Keep continuity with the existing Story Events.
   - Use only characters and facts from `CONTEXT.md` / ADR-0006 / `content/forest.json`; no new named people.
2. **`src/client/story/dialogue_panel.gd`** — AAC-style bottom dialogue box (dark navy #1c2233 panel, light grey 2 px border
   with corner diamonds, Pixelify Sans white text with outline): portrait box on the left, speaker name, typewriter text
   (instant when Reduced motion), `▶ Next [Enter]`, `Skip [Esc]`. Portraits: use `assets/characters/<class>/portrait.png`
   when the speaker's current class has one (read `assets/characters/manifest.json`), otherwise a code-drawn silhouette with the
   speaker's initial. Emits `finished`. Respects text scale; no overlap at 1280×720 and scale 1.4.
3. **`src/client/story/chapter_card.gd`** — full-screen fade card: "Chapter N" small, title large gold, subtitle; 2.5 s then
   fades (static + click/Enter to continue when Reduced motion is on).
4. **`src/client/story/story_director.gd`** — reads `story_mode.json`; given the client's events/snapshots (same data
   `ClientApp` receives) decides which scene/card to show (prologue at match start, card on each new Layer, triggers above,
   each scene at most once per run) and queues them so they never overlap a player decision (show them between phases).
   It only presents text — no game logic, never sends commands except nothing at all.
5. **`src/client/story/story_launcher.gd`** — builds an in-process `MatchServer` (SystemClock, `GameRng` with a random seed or a
   given one, `ForestContent`) and a `LocalConnection`, exactly like `tools/ui_preview.gd` does, and hands the connection to
   `ClientApp.use_connection(...)`. Also `stop()` to tear it down. No network.
6. **`src/client/story/story_save.gd`** — `save(data: Dictionary)`, `load() -> Dictionary`, `has_save() -> bool`, `clear()` on
   `user://story_save.json` (atomic write: temp file then rename; version field; tolerate a corrupt file by reporting no save).
7. **`tools/story_preview.gd`** — a `-s` script that opens a window showing the prologue in `DialoguePanel`, then a chapter card,
   and saves screenshots to `--out=DIR` (like `ui_preview.gd`). Also `--interactive` keeps the window open so a human can click.
8. Tests (new files only, picked up by `tests/run_tests.gd`): `tests/client/test_story_content.gd` (every scene's speakers are
   valid, every trigger in ADR-0014 exists, chapters 1–5 + boss present, no empty text) and `tests/client/test_story_save.gd`
   (round trip, clear, corrupt file → no save). If the runner does not discover `tests/client/`, put them under `tests/match/`
   with a `test_story_` prefix instead.

## Verify

1. `bash scripts/run_tests.sh` → 0 failed (paste the exact summary line).
2. `"$GODOT" --path . -s tools/story_preview.gd -- --out=build/story` at scale 1.0 and `--scale=1.4`; view the PNGs:
   readable, nothing overlaps, looks like the AAC panels.

Report in English: files created, number of lines per scene, test summary line, screenshot paths.
