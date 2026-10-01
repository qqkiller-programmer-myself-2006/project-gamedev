# Task: T38 — restore the Story Party class-picker popup (port from an unmerged branch onto current main)

The feature was built on the old branch `origin/claude/remote-control-dc3630` in ONE commit, `dc12d37`
("feat(ui): Story Party picks Classes from a character-image popup") but never reached `main`. `main` has since changed a lot
(title menu redesign, x1.4 text scale, responsive layout, folder restructure). Port the behaviour onto current `main`; do not
blindly cherry-pick over newer code.

## Read first
`AGENTS.md`, `CONTEXT.md`, `docs/guides/testing.md`, and the original commit: `git show dc12d37` (message + diff of
`src/client/title/title_screen.gd`, `tests/client/test_story_party_picker.gd`).

## Required behaviour (from the original commit message — keep it)
- Story Party rows are buttons that show the chosen Class with its portrait. Click or Enter on a row opens a picker on the right,
  over the campfire, with 5 Class cards: portrait (nearest filter), name, role, first Skill with its Energy cost.
- Current choice uses the `SelectedButton` theme variation; other cards use `HudButton`.
- Keys: 1–5 pick, arrows and Tab cycle cards, Enter confirms, Esc closes (Esc again = Back). Focus returns to the row.
  Leaving the screen frees the picker.
- Defaults and the class ids passed to `start_story` are UNCHANGED.
- Layout must fit at 1280x720 with text scale 1.4 and not clip at other supported sizes the current title/story-setup screen
  already supports (see the responsive work and `tools/dev/ui_preview.gd`).

## How
1. Find where Story Party setup now lives in `main` (it may have moved from `src/client/title/title_screen.gd`; `git grep -n
   "start_story\|story_party\|Party" src/client`). Re-implement the picker there using the CURRENT theme variations, text-scale
   helpers and ui_text strings. Reuse existing UI helpers; do not duplicate.
2. Port the tests (`git show dc12d37:tests/client/test_story_party_picker.gd`) to the current tests folder layout
   (check how other `tests/client/**` files are organised and registered in `tests/run_tests.gd`) and adapt to current APIs.
   Keep all 6 original test cases. A script moves/lives with its `.uid`.
3. Add a preview case if `tools/dev/ui_preview.gd` has a natural place for a story-setup screenshot; save to the usual
   screenshots folder and report the path. Skip if it needs a big refactor.
4. Thai strings: if the repo uses i18n catalogs (`i18n/`), run the extract/check tools so new strings are in the catalog
   (`tools/i18n/`). Follow existing practice.

## Constraints
No behaviour change outside Story Party setup. Do not touch `.claude/agents`, `.ai/checkpoint.md`, assets. Do not commit/push.
One Godot process at a time. `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe`.

## Verify (paste exact lines in the report)
- Record the full-suite pass count BEFORE you change anything; after: `bash tools/run_tests.sh` → baseline + new tests, 0 failed.
- `"$GODOT" --headless --path . --import` exits 0, no new script errors.
- The picker tests pass, including text scale 1.4 fit.
- `git status --short` listing.

## Report (under 200 words)
Where the code lives now, files changed, test counts before/after, screenshot path (if any), anything from the original
behaviour you could not keep and why.
