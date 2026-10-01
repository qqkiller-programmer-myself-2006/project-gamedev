# T42b — Path Vote still overflows to the RIGHT at text 1.4 (follow-up to T42)

T42 fixed the vertical footer, but at text scale 1.4 the Vote screen is still wider than the viewport: in
`build/chk/03_vote.png` (seed 11, `--scale=1.4 --resolution=1920x1080`) the right edge of the vote panel is cut off —
the intro sentence ("... and a tie is broken at random.") runs past the screen edge, the route card and the
timer progress bar are cropped, and the Tip box also runs off the right. Something in `src/client/match/vote_panel.gd`
(or the `match_screen.gd` layout that hosts it) has a minimum width larger than the viewport (candidates: the card
`custom_minimum_size = Vector2(250, 0)`, the chip rows (FIGHT / Combat / Recommended; EXP / Gold / Items) that do not wrap,
the timer row = ready label + bar + countdown, the party list column being too wide, the Tip width).

Do:
1. Find the control(s) forcing the width (print `get_combined_minimum_size()` of the panel's children at scale 1.4) and fix them so the
   whole Vote screen fits inside the 1280x720 logical viewport at text scales 1.0 / 1.2 / 1.4: wrap or shrink chip rows
   (`HFlowContainer`), allow the card to shrink, narrow the party column or let the left column scroll, keep the Tip inside.
2. Extend `tests/client/t42_vote_summary_layout_smoke.gd`: for 1.4 scale and 5 party members, the global rect of the vote panel, the
   timer row, the progress bar and the Tip all lie inside the viewport rect (x + width <= viewport width). The existing check must
   have missed this - find out why and make it real.
3. Also check Summary and the Merchant/Rest Tip at 1.4 for the same horizontal overflow; fix only if it is the same cause.

Verify: `bash tools/run_tests.sh` -> 0 failed (>= 448 passed); preview `--out=build/t42b --seed=11 --scale=1.4 --resolution=1920x1080
--class=rogue` and LOOK at `03_vote.png` at full resolution: the right edge of every panel and the progress bar must be visible.
Report (<150 words). Do not commit or push. Remove nothing outside this task.
