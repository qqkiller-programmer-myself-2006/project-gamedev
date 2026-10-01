# T34 — Redesign the Path Voting screen (owner request: "redesign")

Files: src/client/match/vote_panel.gd (route cards), the party/top-bar pieces it uses in src/client/match/match_screen.gd and src/client/ui/ui_kit.gd. Base branch already contains T30 fixes (U31 fit/scroll) — keep them working.

Reference images in docs/references/ui_mockups/ (view all four):
- path_vote_current_1920.png : the CURRENT screen (1920x1080, Story mode) — what must be improved: HP bars with text overlapping the bar, party cards without portraits, plain text header, no icons in the top bar, featured card is a flat text box, "Alternatives" cards cut off below the fold, no ready indicator.
- mockup A (portraits + "Recommended" badge + big featured card with background art + "Other path" row + "N of M ready" segmented bar + log/tip at the bottom),
- mockup B (layer stepper 1-5/BOSS in the top bar, party cards with READY / WAITING / YOU badges, featured card with FIGHT badge, reward chips EXP/Gold/Items, big yellow "Vote for <route> (1)" button, second card for the other path),
- mockup C (Party panel with check/circle ready marks, featured card with art and Recommended badge, "Other path / See other path >" row, route map strip on the right).
The mockups are AI-generated concept art: match their LAYOUT, hierarchy and feel (dark navy panels, gold accent, pixel font for titles), not their exact pixels. Primary direction = mockup B (keeps the existing layer stepper and READY/WAITING semantics), borrowing the "Recommended" badge and compact "Other path" row from A/C. Do not add the route map from C.

Requirements:
1. Top bar: icon + "Forest" (or Cave by layer), layer stepper, "Layer N of 5", Gold with coin icon, Clues, Settings [F2], Leave [Esc] — with the existing icons from assets/icons (Icons helper). No overlap at 1280x720, 1920x1080, text scale 1.4.
2. Party panel: hero portrait (assets/heroes/<class>/portrait.png; classless = Bram portrait), name, Lv + Class, HP bar with the number OUTSIDE/right of the bar or clearly inside without being cut, and badges YOU / READY / WAITING / AI (multiplayer). In Story mode (single controller) show no READY/WAITING and no vote tallies (existing behaviour; tests in tests/client/test_story_ui.gd define it — keep them green or update deliberately).
3. Featured route card (first server-ordered option): type badge (FIGHT/SHOP/LOOT/CLASS/...), route name in the pixel title font, description, reward/feature chips with icons, a background art strip built from existing assets (assets/backgrounds/forest.png or cave.png cropped/tinted — no new art generated), "Recommended" badge, big primary vote button "Vote for <name> [1]" (Story: "Choose <name> [1]"). Keys 1-3 still follow server order.
4. Other routes: compact rows "Other path: <name>" with type badge and a button/row that votes for it (keys 2/3); must never fall below the fold — use layout so featured + others fit at 1280x720 (scroll only at 1.4 text scale).
5. Multiplayer: "N of M ready" with a segmented progress bar, vote tallies and voter names on cards as today; countdown timer kept when a deadline exists.
6. Keep: keyboard focus order, tooltips, UiText strings tested in tests; do not change server or rules.
7. Tests: update/add tests in tests/client for the new layout (no overlap/fit at 1280x720 and scale 1.4, story hides ready status, multiplayer shows it). Whole suite must pass: `GODOT=<godot console exe> bash tools/run_tests.sh`.
8. Screenshots: `"$GODOT" --path . -s tools/dev/ui_preview.gd -- --out=build/ui --seed=11 --speed=24` (+ `--resolution=1920x1080`, `--scale=1.4`) and a Story-mode capture if tools/dev/story_preview.gd supports it; list PNG paths (03_vote.png).
Final message: changed files, exact test summary, screenshot paths, deviations from the mockup and why.
