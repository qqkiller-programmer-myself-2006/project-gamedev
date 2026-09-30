# T32 — Integrate the 4 owner-supplied sprite sheets (issues #85 and #75)

The owner supplied four sprite sheets (saved in art_source/characters/):
- old_swordsman_sheet.webp  -> enemy/trainer id `old_swordsman`
- shrine_spirit_sheet.webp  -> `shrine_spirit`
- thornback_boar_sheet.webp -> `thornback_boar`
- veteran_hunter_sheet.webp -> `veteran_hunter`
Each sheet is a 3 columns x 2 rows grid of 6 poses on a WHITE (opaque) background, no transparency. Frames read left-to-right, top-to-bottom. Poses are a mix of calm/ready stances and action/attack poses (with teal slash/magic effects). Look at each sheet yourself (view the images) and decide which frames are idle and which are attack. The effect swirls (teal) belong to the attack frames.

Do:
1. Write tools/art/slice_remaining_sheets.py (follow tools/art/slice_bram_sheet.py and tools/art/slice_elder_thornwarden.py conventions: cut each frame, remove the white background to real alpha (flood/threshold from edges, keep teal glow effects and light hair/beards intact, no white halo), crop tight, paste onto a common per-animation canvas anchored on the mass-weighted x-centre with a shared baseline). Also write a portrait crop if the existing enemy/hero assets use one. Find column/row boundaries from the actual pixels, not guesses; frame effects may cross nominal grid lines.
2. Output PNGs under assets/enemies/<id>/ (idle_00..., attack_00...) following the existing enemy layout in assets/enemies/ (see assets/enemies/manifest.json, elder_thornwarden) and register each id in assets/enemies/manifest.json. hurt/die reuse idle frames like Elder Thornwarden. Facing: enemies face LEFT toward heroes in battle? check how elder_thornwarden/"right" key and SpriteSet handle facing and flip if needed so the sprites face the heroes.
3. Wire them in: check src/client/match/battle/sprite_set.gd and battle_token.gd (thornback_boar has a colour entry and was "skipped" for sprites). Make thornback_boar, old_swordsman, veteran_hunter, shrine_spirit use the new sprites wherever the old block/placeholder was used. Do not change game rules or content/*.json stats.
4. Add tests in tests/client/ (like tests/client/test_enemy_sprite_set.gd) that each of the four ids loads idle + attack frames with non-empty alpha and transparent corners.
5. Run `godot --headless --path . --import` once so .import files are generated for the new PNGs (the repo commits *.png.import for assets/enemies — check and follow that convention).
6. Verify: `GODOT=<godot console exe> bash tools/run_tests.sh` all passing; then a preview screenshot (`tools/dev/ui_preview.gd` or `--dev --playtest --jump=...`) showing at least the boar in a fight if reachable; report paths.
Final message: what was produced per id (which source frames became idle/attack), changed files, exact test summary line, anything not done.
