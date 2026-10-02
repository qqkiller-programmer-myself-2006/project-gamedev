# Task: U27 list-screen Esc menu must not cover the party cards

Problem (seen in a real Godot window): on list screens of a Match (path vote etc.) the first Esc opens the menu
(Clues / Settings / Leave Match) built in `src/client/match/match_screen.gd` (`_list_menu`, positioned
`Vector2(12, 72)` at line ~123). It sits on top of the first party card (Arin: name/HP hidden). It must not cover any party card.

Do:
1. Position `_list_menu` so it covers no party card and no header button. Preferred: place it just right of the left party
   column (x = party column right edge + margin, below the header), e.g. computed from `_party_scroll` rect when the menu is shown
   (layout is not final at `setup`, so set the position in the code path that makes it visible: the Esc handler in `handle_key`),
   and clamp to stay inside the viewport at text scale 1.0 and 1.4, and at 1280x720 and 1920x1080 window sizes.
2. Keep behaviour: first Esc opens + focuses the first item, second Esc closes, leaving the screen hides it.
3. Add a regression test to `tests/client/test_ui_polish_restore.gd` (or a new test file in `tests/client/`) that opens the menu on a
   real MatchScreen at text scale 1.0 and 1.4 and asserts the menu's global rect does not intersect any party card rect
   (use real control rects; see `tests/client/t35_layout_smoke.gd` for the pattern of building a screen and reading rects).
   Keep `.uid` files with new scripts.
4. Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` → 0 failed, smoke scripts pass
   (record baseline first). Capture a screenshot of the opened menu (non-console Godot
   `Godot_v4.7.2-stable_win64.exe --rendering-driver opengl3 -s <script>`; the throwaway script may live outside the repo) and save it as
   `docs/screenshots/u27_menu_open.png`.

Constraints: change only what is needed; no behaviour change elsewhere; do not touch `.claude`, `.ai/checkpoint.md`, assets, CI.
Do not commit or push. Do not use `git show ref:path` in this shell (path mangling). One Godot process at a time.

Report (under 150 words): where the menu is placed now, files changed, test counts before/after, screenshot path.
