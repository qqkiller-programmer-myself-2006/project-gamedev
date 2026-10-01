# T90 — Redesigned camp (Rest/Merchant) overflows the screen at 1.4x text

At 1280x720 x1.4 the new camp (PR #125 camp redesign) breaks: the Equipment panel runs past the right screen edge (the ">" next-character button is cut off), the bottom of all three columns runs below the screen (the "Hide" button sits on top of the Charm 2/3 slots, Invest Points is off-screen), and the Crafting list is so narrow that words break mid-word ("Bramb / le Quiver"). At x1.0 (1280x720 and 1920x1080) the camp is fine. Reproduce: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t90 --seed=5 --speed=12 --scale=1.4 --resolution=1280x720` and view 10_rest.png (seed 5 gives Rest, seed 11 gives Merchant 08_merchant.png; seed 9 gives both). Note: at --resolution=1920x1080 --scale=1.4 seed 5 the 10_rest.png came out as a combat shot (preview timing); use seed 9 or 11 for that size.
Do:
1. Make Rest AND Merchant fully usable at 1280x720 x1.4: every column and control inside the viewport; the right column may scroll internally but its width and buttons ("<", ">", Invest Points, Hide) must be on screen; columns may use a smaller fixed portrait strip or 2-line headers; no mid-word breaks (allow the Crafting/Shop columns more width at the expense of the middle Inventory column or reduce paddings at large text).
2. Keep x1.0 at both resolutions pixel-similar (do not regress) and check 1920x1080 x1.4.
3. The Tip box should not cover list content at x1.4 (let it sit in free space or collapse to one line).
4. Add a layout test (tests/client) asserting at text scale 1.4 and a 1280x720 viewport that the camp's key controls (next-character button, Invest Points, Ready, Hide) rectangles lie inside the viewport.
Constraints: this worktree only (branch ai/t90-camp, based on ai/t88-edge); local commit OK; no push/PR; never hand work to opencode.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 453); view 10_rest.png and 08_merchant.png at 1280x720 x1.0, x1.4 and 1920x1080 x1.0, x1.4 yourself.
Final message: per screen/combo pass/fail, changed files, exact test summary, screenshot paths.
