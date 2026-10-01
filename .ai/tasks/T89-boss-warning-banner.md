# T89 — Boss WARNING banner covers the boss and the party list at 1.4x text

At 1920x1080 x1.4 (and probably 1280x720 x1.4) the Boss turn shows a large banner (Phase 1/3 title plus "WARNING: Crushing Root next turn, aimed at Arin! Guard to halve it, or have a Guardian Protect them.") that covers the boss nameplate/HP, hides the first row of the left turn list (Arin's row) and cuts its own last line ("Guardian Prote..." under the boss plate). Reproduce: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t89 --seed=11 --speed=10 --scale=1.4 --resolution=1920x1080`, view 07_boss_warning.png and 06_boss_turn.png (also 1280x720 x1.0 and x1.4).
Do:
1. Keep the warning fully readable but make it never cover the boss nameplate, the turn list or the bottom action bar: e.g. dock it as a compact bar at the top-centre between the turn list and the boss plate, limit its width, wrap the text, and shorten the phase title row; the text may grow in height only downward into free space.
2. The battle log box bottom-left ("den takes 18." shows a clipped line at 1.4x): make the newest line fully visible or let the box grow upward/wider at 1.4x without covering hero nameplates.
3. Add a small layout test if feasible (banner rect does not intersect the boss plate rect at 1.4x).
Constraints: this worktree only (branch ai/t89-boss-banner, based on ai/t88-edge); local commit OK; no push/PR; never hand work to opencode.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 453); view 07_boss_warning.png and 06_boss_turn.png at 1280x720 x1.0, 1280x720 x1.4, 1920x1080 x1.0, 1920x1080 x1.4.
Final message: per combo pass/fail, changed files, exact test summary, screenshot paths.
