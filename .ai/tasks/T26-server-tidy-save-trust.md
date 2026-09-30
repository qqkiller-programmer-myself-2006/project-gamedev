# T26 — Server tidy-up + test backfill (#71) and the rest of the Story save trust boundary (#63)

Read `AGENTS.md` ("Where things live"), `gh issue view 71`, `gh issue view 63` (the last comment lists what is still open),
`docs/review/2026-09-29-server-review.md` findings S13, S14, S16, S22 (paths are pre-restructure), `docs/adr/0012-*.md`,
`docs/adr/0014-offline-story-mode.md`.

## #63 remaining
1. Attribute totals in a Story save are checked against content (level-based stat points: base + points per level from
   `content/forest.json`), not against the save's own `_profile` — a forged save with extra attribute points is rejected.
2. Clue entries: every clue must be a known clue id with the expected type; unknown/extra keys rejected.
3. Tests: unknown gear id, forged attributes, wrong clue type, clue id not in content.
4. A save that fails validation is cleared (or marked broken) so Continue is not offered again; the player sees the error once.
   (Client part: `src/client/story/story_save.gd` + the Continue button — keep it minimal.)
5. Saves written before `version` existed: keep rejecting, but the message says the save is from an older build.

## #71
6. S14: `run.gold` — remove it or make it a derived total of personal gold; fix every reader; tests.
7. S16: decide enemy first-turn Energy per ADR-0012 §3 (+1 at the start of every own turn, including the first) — implement it,
   update the ADR line if you change the rule, and fix tests that assumed the old behaviour.
8. S22: add tests for any rule in the P0/P1 review items that still has none (check the list in S22).

## Rules
- Files: `src/match/**`, `src/profile/**`, `src/client/story/story_save.gd` and the Continue button's file only,
  `src/client/ui/ui_text.gd` (new texts), `docs/adr/0012-*.md`, `docs/adr/0014-*.md`, `tests/**`.
  Not `src/client/match/**`, `src/client/title/**`, `src/client/lobby/**` except the Continue button (another executor
  is adding icons there).
- Balance must stay 70–92%: `"$GODOT" --headless --path . -s tools/dev/simulate.gd -- --seeds=100 --humans=1,2` plus
  `--loadout` and `--story --humans=1`; if item 7 moves it out, tune enemy energy content, record in `docs/design/balance.md` (UTF-8).
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
  (baseline 327). ONE Godot process at a time. Report in English: per item what changed, tests, win rates, test line.
