# T24 — Story pacing and control (#67)

Read `AGENTS.md` ("Where things live"), `docs/adr/0014-offline-story-mode.md`, `gh issue view 67`, and in the reviews
(`docs/review/2026-09-29-server-review.md`, `...-client-review.md`) findings S9, S17, S20, C7, C11, C12, C13, C14, C15, C25
(paths are pre-restructure; map with "Where things live").

## Server (`src/match/**`)
1. S9: in Story rooms no timer runs for Merchant, Rest, Class offer, Story vote and Story read (the player controls all five
   and plays at their own pace). Online rooms keep every timer.
2. S17: `class_choice` in a Story room applies to the slot the command names (the player controls every slot).
3. S20: Story `voters()` / `needs_ready()` use the host's slot, not a hard-coded 0.
4. Story gold regression guard: add a test that a Story outcome with Gold and no clue pays the Gold (the bug was fixed on
   the integration branch; keep it fixed).

## Client (`src/client/story/**`, `src/client/match/**`)
5. C7: the story director never shows a scene over a pending decision (vote, class offer, merchant/rest ready, target pick) or
   while hotkeys are needed; scenes queue until the decision is made.
6. C11–C14: portraits in story dialogue follow each character's class sprite (`assets/heroes/<class>/portrait.png`); Story copy
   lives in `content/story_mode.json`; the director's state resets on a new match and restores on Continue.
7. C25: the lead character uses the player's profile Race and Boons (ADR-0014), falling back to Human with no boons.

## Rules
- Files: `src/match/**`, `src/client/story/**`, `src/client/match/**`, `content/story_mode.json`, `tests/**`,
  `tools/dev/story_preview.gd`. Not `assets/icons/**`, `tools/art/**` (another agent works there).
- Tests for 1–4 and director queueing (6). Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`
  -> exact line, 0 failed (baseline = current integration count); `"$GODOT" --headless --path . -s tools/dev/simulate.gd -- --seeds=40 --humans=1 --story`
  still runs (win rate 70–92%). ONE Godot process at a time. Report in English: per finding what changed, test line.
