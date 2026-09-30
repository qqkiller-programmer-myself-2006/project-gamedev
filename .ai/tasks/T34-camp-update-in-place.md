# T34 — Camp updates in place, search keeps focus (#86, U13 + S4)

Source: `docs/review/2026-09-30-full-qa-report.md` (U13, S4). Client only: `src/client/**`, `tests/client/**`.

Problem: the camp (Merchant / Rest) rebuilds its whole layout on every update (`src/client/match/camp/camp_view.gd` ~114–135).
When a friend buys or presses Ready, scroll positions reset and the search box loses focus. The search box has no `focus_id`, so
the next keystrokes reach `handle_key` (~507–533): "r" presses Ready and digits 1–9 buy items instantly.

1. Build the camp columns once per camp phase; on later updates refresh only what changed (rows, Gold, stock, Ready count,
   equipped Gear, stat points) in place. If a full in-place update is too invasive, the minimum acceptable fix is: remember
   and restore every ScrollContainer position and the focused control (give the search box a `focus_id`) across rebuilds.
2. While a text field (search) has focus, `handle_key` must ignore shortcut keys (r, 1–9, etc.) — typing never triggers a buy
   or Ready.
3. Tests (tests/client): an update while the search box has focus keeps focus and its text; typing "r1" into search does not
   send Ready or a buy; scroll position survives an update.

Verify (one Godot process at a time; `$GODOT` set by the runner): `"$GODOT" --headless --path . --import`,
`bash tools/run_tests.sh` → 0 failed, no fewer passed than before. Preview merchant + rest (`tools/dev/ui_preview.gd`, seed 11 =
Merchant, seed 3 = Rest; `--out=build/t34`) and look at them: layout unchanged from before.

Report (under 200 words): per item done / not done, exact test summary line, screenshots looked at, changed files, stray files.
Do not commit or push.
