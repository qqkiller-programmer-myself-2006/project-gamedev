# T42 — Path Vote overflow and Summary banner overlap at 1920x1080 / text 1.4

Client only: `src/client/**`, `tests/client/**`. Theme rules: `docs/design/ui-style.md`, `UiKit`. Files: `src/client/match/vote_panel.gd`,
`src/client/match/summary_panel.gd`, `src/client/match/match_screen.gd`.

Repro (windowed preview, one Godot process at a time, `$GODOT` set):
`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/t42 --seed=11 --scale=1.4 --resolution=1920x1080 --class=rogue`
Look at `03_vote.png` and `90_summary_defeat.png`. Also check `--seed=3`, and 1280x720 at scale 1.0 and 1.4.

1. **Path Vote (03_vote)**: at text 1.4 the right column (layer title, path cards, "Votes: N", "N of M ready", "Vote closes in Ns")
   runs off the bottom edge and the Tip text is cut mid-sentence. Fix so nothing important is clipped at 1280x720 and 1920x1080,
   scales 1.0 / 1.2 / 1.4: let the path area scroll, or use compact rows; keep the status/ready/timer row always visible
   (outside the scroll area); Tip must not cover the vote content.
2. **Summary (90_summary_defeat, also victory)**: the "Defeat" / "Victory!" banner is drawn over the "DEFEAT" / "VICTORY" title.
   Show one or the other (suppress the banner once the Summary panel is up, or move it), and make sure the banner never blocks
   Esc / F2 or buttons.
3. Tests (tests/client): with 5 party members at text scale 1.4 the vote status/timer row rect lies inside the viewport and is not
   overlapped by the Tip; the Summary title rect does not intersect an active banner rect. Do not weaken existing tests.

Verify: `--import`, `bash tools/run_tests.sh` -> 0 failed, not fewer than 447 passed; the previews above, look at vote and summary
images for victory and defeat. Report (<200 words): per item done / not done, exact test summary line, images looked at, changed
files, stray files. Do not commit or push.
