# T1 round 3 — combat layout: fixed positions, no overlaps

Continue on this branch. Same rules/file limits as `.ai/tasks/T1-combat-ui.md`. Round 2 improved the figures a lot — keep
them. QA of `build/ui_t1_r2_final/04_combat_turn.png` and `06_action_banner.png` still finds overlaps. Use the exact
numbers below (base 1280×720, multiply positions by the viewport scale; text scale only changes font sizes).

1. **Fixed unit slots, no overlap.** Figure height ≈ 110 px, feet at the slot point, nameplate directly under the feet.
   - Party (5): front row feet y = 300 at x = 300, 460, 620; back row feet y = 480 at x = 380, 540.
   - Enemies (up to 5): front row y = 300 at x = 800, 960, 1120; back row y = 480 at x = 880, 1040. Use content `row`
     (front/back) to pick the row; fill left to right. The Guardian Boss alone: one big figure centred at x = 960, feet y = 440.
   - Figures in the back row are drawn after (on top of) the front row. No figure may cover any nameplate.
2. **Compact nameplates like ref 04/07**: 140×36 px, near-black 85% alpha. Row 1: name, 11 px font, left aligned.
   Row 2: **one row** with the red HP bar (60% width, 14 px tall, "hp/max" 9 px centred) and the blue Energy bar (40% width,
   same height, "e/max" centred) side by side. Status icons sit just above the plate's top-left.
3. **Initiative list**: entry height 46 px, width 150 px. Name line 11 px font. Then HP bar 10 px tall and Energy bar
   10 px tall with 2 px gap, each with its numbers in an 8 px font centred **inside** the bar. Nothing drawn outside its bar.
   Entries of units that already acted this round are dimmed to 60% (still readable — not 20%).
4. **Action banner** (ref 06): opaque stripe `Color(0.18, 0.18, 0.18, 0.92)`, full width, 70 px tall, centred at y = 585,
   rotated −1°, name in 34 px pixel font. Visible for 1.6 s at full opacity, then fades 0.3 s. While it shows, and whenever
   it is not your turn, the HUD collapses to header + bars (no buttons) and sits at the very bottom (y 645–715).
5. **"Your turn!"** only while the current actor is your character; hide it immediately when anyone else acts.
6. **Toasts** at top centre y = 12, and must not overlap the region box or the Turn label.
7. Re-capture with seeds 11 and 3 at scale 1.0 and 1.4: `04_combat_turn`, `04_combat_skills` (Fight grid open),
   `06_action_banner` (the stripe clearly visible), `11_combat_reward`, boss screens. Check every image yourself for
   overlapping boxes/text before finishing.

Verify: `bash scripts/run_tests.sh` → 0 failed. Report in English: items 1–7 done/partial, test line, screenshot paths.
