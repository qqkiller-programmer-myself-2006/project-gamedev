# T88 — Redesigned battle HUD clips at the right screen edge

After PR #119 (combat redesign) the right-hand status badges ("Turn", "P Ready", "S E2") run off the right edge of the screen: at 1280x720 x1.0 the "S E2" badge is cut in half, at 1920x1080 x1.4 "Ready" shows as "Re". Reproduce: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t88 --seed=11 --speed=10 [--scale=1.4] [--resolution=1920x1080]`, view 04_combat_turn.png.
Do:
1. Fix so every badge is fully inside the viewport at 1280x720 and 1920x1080, scale 1.0 and 1.4 (anchor/margin inside the screen, shrink or wrap the row; the badges must stay readable and not cover the bottom action bar or the top-right "Forest (1/5)" / menu buttons).
2. While there, check the other redesigned combat screenshots in the same run (items, targets, skills, boss turn, boss warning, reward) for anything clipped at any screen edge or overlapping the bottom bar; fix small things, list anything bigger.
3. Add a small layout test if feasible (e.g. assert badge rect within the viewport at scale 1.4) in tests/client.
Constraints: this worktree only (branch ai/t88-edge, based on ai/t87-polish); local commit OK; no push/PR; never hand work to opencode.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 450); view the PNGs at all four size/scale combos.
Final message: per combo pass/fail, changed files, exact test summary, screenshot paths.
