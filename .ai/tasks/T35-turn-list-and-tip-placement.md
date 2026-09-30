# T35 — Turn list always shows the current actor; Tips don't cover content (#83, U7 + U8)

Source: `docs/review/2026-09-30-full-qa-report.md` (U7, U8). Client only: `src/client/**`, `tests/client/**`. Theme rules in
`docs/design/ui-style.md` / `UiKit`.

1. **U7 — turn-order list** (`src/client/match/battle/battle_view.gd` ~67–79, ~403–445): the list on the left never scrolls. The
   current actor (often the player) is cut off at the bottom at 1280x720, especially at text scale 1.4, and with 10 units most
   are hidden. Keep the current actor visible at all times (scroll it into view, or show a window of N entries around the
   current one, or make rows compact) at 1.0 / 1.2 / 1.4 text scale, 1280x720 and 1920x1080.
2. **U8 — Tip placement** (`battle_view.gd` ~99–109 and the shared Tip panel): the Tip box covers the region title in battle and
   the Inventory list in Merchant. Cap its height and dock it where it hides no information on every screen that shows Tips
   (battle, merchant, rest, vote). One placement rule in the shared Tip code, not per-screen hacks.
3. Tests (tests/client): the current actor's row lies inside the list's visible rect with 10 units at text scale 1.4; the Tip's
   rect does not intersect the region title / inventory list rects.

Verify (one Godot process at a time; `$GODOT` set by the runner): import, `bash tools/run_tests.sh` → 0 failed, no fewer passed.
Windowed previews `tools/dev/ui_preview.gd -- --seed=7 --out=build/t35`, `--scale=1.4 --out=build/t35_x14`, and
`--resolution=1920x1080 --out=build/t35_1080`; look at combat turn, merchant and vote images.

Report (under 200 words): per item done / not done, exact test summary line, screenshots looked at, changed files, stray files.
Do not commit or push.
