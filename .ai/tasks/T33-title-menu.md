# T33 — Title screen: remove the DEV button, centre the menu

Owner request (with a screenshot of the current title): "remove the DEV button, put the menu in the centre of the screen".

File: src/client/title/title_screen.gd (see _show_menu, _show_play, _show_credits, other narrow sub-panels; story setup is wide and stays as is).

Do:
1. Remove the "[DEV] Playtest  >" button from the title menu for everyone. Keep the command-line dev path working (`--dev --playtest --jump=... --class=... --seed=...` documented in README/docs/guides/running.md) — only the on-screen button and its panel entry point go away. If the playtest panel (_show_playtest) becomes unreachable from the UI, delete that dead UI code only if nothing else (tests, CLI, ClientApp.can_playtest/start_dev_playtest) uses it; otherwise keep it. Update or remove tests that click the DEV button (grep tests/ for "playtest", "dev" meta, "focus_id" "playtest").
2. Centre the main menu panel (Welcome, Play, Settings, Credits, Quit) horizontally in the viewport, with the game title/subtitle staying at the top. Make it robust at 1280x720 and 1920x1080 and at text scale 1.4: use anchors/containers (e.g. CenterContainer or PRESET_CENTER_TOP) rather than fixed x=88; keep it from overlapping the campfire/characters scene at the bottom and let it stay inside the viewport (scroll if needed). Apply the same centring to the other narrow title sub-panels (Play/room join, Credits) so navigating does not make the panel jump sideways. Keep the existing _notification/_top text-scale handling working.
3. Keyboard focus: Play stays the first focused button; Esc/back behaviour unchanged.
4. Tests: update tests/client accordingly (e.g. tests/client/test_accessibility_baseline.gd, t35_layout_smoke.gd if they assume the old position) and add one test that the menu panel's horizontal centre is within a few px of the viewport centre at 1280x720 and 1920x1080.
5. Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all passing; capture the title screenshot with tools/dev/ui_preview.gd (`--out=build/ui --seed=11 --speed=24`, also `--resolution=1920x1080` and `--scale=1.4`) and report the PNG paths (01_title.png).
Only touch src/client/title, tests/client, docs mentioning the DEV button. Final message: changed files, exact test summary line, screenshot paths.
