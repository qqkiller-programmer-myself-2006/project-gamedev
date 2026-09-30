# T18 — Slice the owner's enemy sheets and backgrounds (#73, step 1)

Read `AGENTS.md`, `gh issue view 73`, and the existing hero slicer `tools/slice_character_sheet.py` +
`assets/characters/manifest.json` (same idea, different template). Open every source image and look at it yourself.

## Sources (already committed, never edit them)
- `art_source/enemies/forest/{goblin,golem,slime,thief,wolf}_sheet.webp`
- `art_source/enemies/cave/{kobold,minotaur,skeleton,giant_spider}_sheet.webp`
- `art_source/backgrounds/{forest,cave}.webp`

Enemy sheet template (1536x1024, flat dark navy background, pixel art): title at top-left; labelled rows on the left —
IDLE, WALK, RUN (the slime has JUMP instead of RUN), ATTACK (some frames carry a slash/web/rock effect that belongs to the
frame), HURT (small star/spark effects belong to the frame), DIE; a large portrait at top-right; a SIZE box and a COLOR PALETTE
on the right; most sheets have a VARIANTS row at the bottom with captions (goblin, thief and wolf have none; the spider has a
WEB EFFECT strip on the right). Frame counts and positions differ per sheet: detect them (connected components on a
background mask, rows grouped by y), do not hard-code one sheet's pixels.

## Build (NEW files only)
1. `tools/art/slice_enemy_sheet.py` (Python 3 + Pillow; numpy is NOT installed): background -> transparent (tolerance on the
   sampled corner colour, keep dark outlines), trim, then for each enemy write
   `assets/enemies/<id>/{idle,walk,run|jump,attack,hurt,die}_<NN>.png`, `portrait.png` (the big art),
   `variants/<caption_lowercase>.png` when present, and `effects/web_<NN>.png` for the spider.
   All frames of one animation share one canvas size with the feet on a common baseline (bottom-centre anchored), like the
   hero manifest. Ignore label text, the SIZE box and the palette swatches.
2. `assets/enemies/manifest.json`: per id -> animations {name: frame_count}, canvas size per animation, baseline, the sheet's
   stated size (32/48/64 px tall), `faces: "right"` (the art faces right; the battle view flips enemies), variants list.
   Ids: forest `goblin, golem, slime, thief, wolf`; cave `kobold, minotaur, skeleton, giant_spider`.
3. `assets/backgrounds/forest.png` and `cave.png` at 1920x1080 (scale to cover, then centre-crop; LANCZOS is fine for these
   painted backgrounds).
4. Run `"$GODOT" --headless --path . --import` so `.import` files are generated; commit them.
5. Contact sheets for review in `build/enemy_contact/<id>.png` (every frame of every animation on a checkerboard, labelled; not
   committed — `build/` is ignored). Look at every one: no cut-off weapons/effects, no label text, no leftover background
   halo, frames in the right order.

## Rules
- Do not modify any existing file (another executor is restructuring the repo in parallel). Only create:
  `tools/art/slice_enemy_sheet.py`, `assets/enemies/**`, `assets/backgrounds/**`. Do not create `art_source/.gdignore`.
- Commit in steps (`feat: enemy sheet slicer (#73)`, `feat: enemy sprites and manifest (#73)`, `feat: battle backgrounds (#73)`),
  explicit `git add <paths>`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Verify: `GODOT=/d/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash scripts/run_tests.sh` -> exact summary line,
  0 failed. ONE Godot process at a time (low RAM).
- Report in English: per enemy the frame counts found, variants, anything the slicer could not separate cleanly, contact
  sheet paths, test line, commits.
