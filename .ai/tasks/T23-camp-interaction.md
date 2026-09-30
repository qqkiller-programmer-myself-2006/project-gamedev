# T23 — Camp interaction bugs (#68) + Assassin badge

Read `AGENTS.md` ("Where things live"), `gh issue view 68`, `docs/review/2026-09-29-client-review.md` findings C3, C4, C6, C16
(paths there are pre-restructure: camp is now `src/client/match/camp/`), `docs/design/ui-style.md`.

1. C3: while the camp search box (or any LineEdit) has focus, camp hotkeys (Ready, buy, tabs) do not fire; Esc leaves the field.
2. C4: Inspect and Abilities buttons open their panels (or are removed if no panel exists — prefer making them work: Inspect
   = the selected item's full stats; Abilities = the character's skills with Energy/cooldown).
3. C6: Equip/Unequip only on your own character on the client; the server rejects equip/unequip for a slot you do not control
   with an error code (check the handler in `src/match/`; change only that handler if it does not already reject, add a test).
4. C16: stat numbers formatted consistently (integers, `+N` for bonuses, percentages with `%`).
5. `src/client/match/battle/battle_token.gd`: the class badge letter for `assassin` is "R" — make it "A"-something unique
   (archer already uses "A": use "As" or a dagger glyph consistent with the others) and fix the glyph drawing branch that
   checks `"R"`.

Files: `src/client/**`, `tests/client/**`, `tools/dev/ui_preview.gd`, and only the equip handler in `src/match/` + a test in
`tests/match/` if needed (another executor edits other `src/match` files — keep your server change tiny).
Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
(baseline 296); windowed ui_preview (`--seed=7 --out=build/t23`), look at the camp/merchant shots. ONE Godot process at a time.
Report in English: per item what changed, test line.
