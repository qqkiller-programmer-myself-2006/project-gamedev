# T31 — Battle input and turn feedback (#81, U9 of #83)

Source: `docs/review/2026-09-30-full-qa-report.md` (U1, U2, U6, U9). Client only: `src/client/**`, `tests/client/**`. Do not touch
`src/match/**` or `content/`. Use Navy + Gold theme rules in `docs/design/ui-style.md` and `UiKit`.

1. **U1 — Tips swallow keys** (`src/client/client_app.gd` ~550–554): while a Tip is open every key except H is eaten. Close the
   Tip on H or Esc and let every other key fall through to the screen (1-3 vote, F/I/O in combat, Ready, ...). Test: with a Tip
   open, a vote key still reaches the screen.
2. **U2 — Action banner hides the HUD** (`battle_view.gd` ~274–306, `match_screen.gd` ~191): the action-name banner ("Frost Lance")
   hides the whole HUD for 1.9 s even on the player's own turn and blocks keys. Never hide the HUD on the player's turn, shorten
   the banner to about 0.9 s, do not block input, and place it above the HUD.
3. **U6 — Whose turn** (`battle_view.gd` ~213–223, 586, 798): the countdown in the player's info row shows the *current actor's*
   timer. Show the timer only when it is the player's turn; otherwise show `_waiting_text()` ("Waiting for Bob..." /
   "Wolf is acting...") — it exists but is never called. Story mode has no timer at all (deadline < 0 = no timer, as
   `story_panel.gd` already treats it).
4. **U9 — First combat tip** (`src/client/ui/ui_text.gd` ~100): rewrite it for the current controls Fight [F] / Items [I] /
   Focus [O], personal Gold/consumable slot instead of "shared bag", and no "15 seconds" when the match is Story. Also check the
   other tips for old [A]/[S]/[D] wording.

Verify (one Godot process at a time; `$GODOT` is set by the runner):
`"$GODOT" --headless --path . --import`, `bash tools/run_tests.sh` → 0 failed (baseline 368 passed). Then windowed:
`"$GODOT" --path . -s tools/dev/ui_preview.gd -- --seed=7 --out=build/t31` (and `--scale=1.4`) and LOOK at the combat-turn images:
your turn shows the HUD and timer, someone else's turn shows "Waiting for ...". The preview bot still presses old A/S/D keys and
times out in the boss fight (issue #90) — if it does, capture the early combat screens only and say so.

Report (under 200 words): per item done / not done, exact test summary line, screenshot paths you looked at, changed files,
stray files. Do not commit or push.
