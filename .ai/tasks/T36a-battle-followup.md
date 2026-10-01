# T36a — Follow-up fixes on the T30 battle polish

Two visual bugs found in the preview screenshots (run `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t36a --seed=11 --speed=24`, view 04_combat_turn.png and 06_boss_turn.png; also at `--scale=1.4`):
1. The battle log box at the bottom-left overlaps the Dain and Wren nameplates/tokens (hero area around x=15-330, y=445-540 at 1280x720). Move or shrink the log (e.g. narrower, above the bottom HUD, or a collapsible panel) so it never covers hero nameplates or tokens, and still shows the newest line.
2. On the boss timeline entry the "Weak: ..." line is clipped. Make the entry grow to fit, or shorten/wrap the weakness text so it is fully visible.
Only src/client/match/battle and tests/client. Add/adjust a test where feasible. Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all passing, screenshots viewed at 1280x720 and 1.4 scale. Final message: changed files, exact test summary, screenshot paths.
