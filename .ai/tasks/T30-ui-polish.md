# T30 — UI polish (issue #87) 

Goal: fix the remaining items of GitHub issue #87 (full list and file:line in docs/review/2026-09-30-full-qa-report.md, items U14-U34). Read that report first.

Already fixed (do NOT redo): U22, U24, U26, U27, U32, U33, U34.
Verified still broken on main (fix these first):
- U14 placeholder text in battle: top-right box shows "All"; bottom-right shows "P OK", "S OK" and "..." buttons with no clear meaning. Give real labels/tooltips or remove.
- U19 target caption ("Power Slash") and skill grid cover back-row heroes; move it so it never overlaps tokens.
- U18 stacked damage numbers on the boss: stagger/offset so they stay readable.
- U16 battle log has no background and cuts the newest line: add a panel and keep the newest line visible.
- U31 Path Voting at 1280x720 / 1.4 text scale: Alternatives and vote status/timer fall below the fold; make the screen fit or scroll cleanly.
- U25 toast covers the lobby Copy code button and top buttons: move toast so it never covers them.
Then check and fix if still present: U15 (item ids vs names), U17, U20, U21, U23 (Forest wording in the Cave: "The Forest is behind you", "Guardian of the Forest", "FOREST SLICE"), U28 (Merchant 1-9 buys without confirmation), U29, U30.

Rules:
- Edit only src/client/** and tests/client/**. Do not change game rules or server code.
- Add or update a headless test for each fix where feasible (tests/client/).
- Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` must be all passing; then capture screenshots with
  `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=11 --speed=24` (and `--scale=1.4`) and check the screens you changed.
- Final message: list each U-number as fixed / already fine / not done, changed files, and the exact test summary line.
