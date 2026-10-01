# T41-r2 — UI fixes after reviewer QA (continue in this worktree, uncommitted changes are yours)

Reviewer screenshots: `build/ux_after/03_vote.png`, `04_combat_turn.png`, `06_boss_turn.png` (1280x720, produced with
`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ux_after --seed=11 --speed=10 --class=mage`; $GODOT = D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe).
NOTE: you MAY run Godot now. Other Godot processes on this machine belong to other sessions; run your own previews one at a time anyway.

Problems still visible — fix all, then regenerate screenshots to `build/ux_after2/` and LOOK at them:
1. Header is ~190 px tall with 4 stacked buttons at the right and the layer chips (1 2 3 4 5 BOSS) stretched into tall thin
   vertical bars. It must be ONE compact row (~56-64 px tall): `[Forest]  [chips in a row, each ~28-36 px square-ish, current one gold]
   [status text, flexible]  [Gold]  [Clues]  [Settings]  [Leave]` side by side. Chips must not use vertical expand; give them a fixed
   min size and `size_flags_vertical = SHRINK_CENTER`. Buttons in a single HBox, shrinking labels/hiding the lowest-priority
   (Clues text -> icon only) before anything overflows at 1280 px and scale 1.4.
2. The freed vertical space goes to the main panel. The bottom-left log panel is an EMPTY box; give it content (the combat log lines
   / "Waiting..." text) or merge it with the Tip panel so no empty panel is shown.
3. The vote card: the second path card is cut off under the first one (a sliver of a card at y~520). Make the card list scroll cleanly,
   or shrink each card (smaller banner image, tighter rows) so at least 2 cards are visible at 1280x720.
4. The previews never show the real battle (turn order, tokens, action bar) — only the "Party sets off" panel. Capture the real battle
   screen too (`04_combat_turn` must show tokens + turn list + log + action bar; adjust the preview script timing/--speed if needed)
   at 1920x1080 and 1280x720, scale 1.0 and 1.4, and verify problem 4 of T41 (turn list, log, action bar fully visible, no overlap).
5. Console showed an engine error with stack `_set_fullscreen (match_screen.gd:275)` <- `refresh (match_screen.gd:165)`. Find the
   message (run the preview and read the log) and fix it.
6. Run `tests/client/t35_layout_smoke.gd` + the accessibility/story UI tests you edited, then the full suite only if no other session's
   Godot is running (`tasklist | grep -i godot`); otherwise say which tests you ran.
Rules as T41. Do not commit. Report: before/after paths, test lines, remaining issues.
