# T22 — Connection lifecycle (#66) and tutorial hints (#69)

Read `AGENTS.md` ("Where things live"), `gh issue view 66`, `gh issue view 69`, `docs/review/2026-09-29-client-review.md`
findings C1, C2, C5, C15, C18, C24 (file:line + failure scenario + fix; paths there are pre-restructure — map them with the
"Where things live" section, e.g. `src/client/screens/` -> `src/client/title|lobby|match/`), `docs/design/ui-style.md`.

## #66 Connection lifecycle
1. C1: connect failure or timeout (e.g. 8 s) shows a visible error (text in `src/client/ui/ui_text.gd`) with a Back button; no
   silent waiting screen.
2. C2: the pending action is cleared on reject, disconnect and every new state, so the next input is never swallowed.
3. C18: the embedded Playtest/Story server stops when the window closes and when returning to the title (no port left bound,
   no orphan process).
4. C24: deferred scroll/focus calls check `is_instance_valid` (no errors on freed nodes).

## #69 Tutorial hints and overlays
1. C5: hints are drawn above the battle HUD and marked seen only after the player closes them.
2. C15: while an overlay (hint, banner, confirm dialog) is open it consumes key input; hotkeys underneath do not fire.

## Rules
- Files: `src/client/**`, `src/net/**` (client side only), `tests/client/**`, `tests/net/**`, `tools/dev/ui_preview.gd`.
  Not `src/match/**` or `content/**` (another executor works there).
- Tests where logic allows (pending-action clearing, hint seen-state, connect timeout via a fake transport).
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` -> exact line, 0 failed
  (baseline 289); windowed ui_preview (`--seed=7 --out=build/t22`) and look at a battle shot with a hint. ONE Godot process
  at a time. Report in English: per finding what changed, tests, test line.
