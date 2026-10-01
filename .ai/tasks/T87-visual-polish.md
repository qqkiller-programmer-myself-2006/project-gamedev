# T87 — Remaining visual polish found on main (issue #87, reopened)

Reproduce with `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t87 --seed=11 --speed=10 --scale=1.4 --resolution=1920x1080` (also 1280x720 and scale 1.0). Look at the PNGs yourself after each fix.
Fix, in priority order (final build is 2026-10-02, keep each fix small and safe):
1. U22 wording: `not_enough_gold` in src/client/ui/ui_text.gd says "The Party does not have enough Gold." Gold is personal (ADR-0012): change to "You do not have enough Gold." (check the rest-camp use too) and update any test that asserts the old text.
2. U26: on the Summary (90_summary_defeat.png, 90_summary_victory) a floating "Defeat"/"Victory" banner box overlaps the big "DEFEAT"/"VICTORY" title. Suppress the banner on the Summary or move it so it never covers the title.
3. U19: in combat Items mode (04_combat_items.png at 1.4) the item tooltip/description card ("[1] Healing Herb / Restores 30 HP to one ally") is clipped at its right edge. Make it wrap or grow so it is fully visible.
4. U19/U18: the "Choose a target on the field (1-N), Esc to go back" caption (src/client/match/battle/battle_view.gd ~l.649, 04_combat_targets.png) overlaps a back-row hero nameplate; move/shrink it so it never covers nameplates or tokens. Stacked floating damage numbers on one target should be offset vertically so they do not overprint.
5. U23: content/forest.json:2259 defeat title "Lost in the Forest" shows when the Party fell in the Cave (Layer 5 / boss). Make the title/body region-aware or neutral ("Lost in the Dark" / fallback), and check other "Forest" strings shown while in the Cave; keep Thai catalog entries (tests/i18n) consistent if they key on the English text.
Constraints: work only in this worktree on branch ai/t87-polish (create from current HEAD if needed); local commit OK; no push/PR; never hand work to opencode.
Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all pass (baseline 447), and view the screenshots for items 2-4 at 1920x1080 x1.4 and 1280x720 x1.0.
Final message: per item done/skipped, changed files, exact test summary, screenshot paths.
