# T9a — Slice the class character sheets into transparent sprite frames

The owner supplied three pixel-art character sheets (1254×1254 JPG) in `assets/characters/source/`:
`archer_sheet.jpg`, `mage_sheet.jpg` (female mage), `swordsman_sheet.jpg`. They are attached as images.
Each sheet uses the same template on a solid dark background RGB (22, 27, 33):

- top-left: large full-body art; top rows: **Idle** (4 frames: Down, Left, Right, Up — the Archer sheet labels this row
  "Archer" instead of "Idle"), **Walk** (groups Down/Left/Right/Up), **Run** (same groups);
- middle: **Attack** (groups Down, Left, Right, Up, each 3–4 frames, some with arrow/slash/magic effects);
- lower: **Hurt** (5 frames) and **Dead** (4 frames, the last ones lying down);
- bottom: a boxed **weapon** picture, a boxed **In-game** example (ignore), a row of **skill icons** (4–5), and large splash art.
Positions differ by a few–40 px between sheets, so detect them; do not hard-code one sheet's pixels for all.

## Files you may create/change

`tools/slice_character_sheet.py` (new), `assets/characters/<class>/**` (new, `<class>` = archer, mage, swordsman),
`assets/characters/manifest.json` (new). Nothing else.

## What to build

1. `tools/slice_character_sheet.py` (Python 3 + Pillow, already installed): for each sheet, make the background transparent
   (colour-distance key around (22,27,33) with a tolerance that removes JPG noise but keeps dark outlines; clean 1-px halos),
   find sprite blobs by connected components (ignore text labels and divider lines by size/aspect), group them into the
   labelled rows/groups above, trim each frame to its bounding box, and save:
   - `idle_down.png`, `idle_left.png`, `idle_right.png`, `idle_up.png`
   - `attack_right_0.png … attack_right_N.png` and `attack_left_0.png …` (keep effects that are part of the frame)
   - `run_right_0..2.png`, `run_left_0..2.png`
   - `hurt_0..4.png`, `dead_0..3.png`
   - `portrait.png` (the large top-left art, background removed), `splash.png` (bottom-right art), `weapon.png`
     (inside the weapon box, background removed), `skill_0..n.png` (each icon)
   All frames of one animation must share one canvas size, bottom-centre aligned (feet on the same baseline), so they don't
   jitter when played. Use a per-sheet config dict in the script for anything that cannot be detected reliably.
2. `assets/characters/manifest.json`: per class — frame lists per animation, canvas size, baseline, and suggested fps.
3. A contact sheet per class `assets/characters/<class>/_contact.png` (all frames on a checkerboard, labelled) so QA can check.

## Verify

- Run the script for all three sheets. Open each `_contact.png` and compare with the source sheet: every frame present, in
  order, not cut off, no leftover label text, no big dark halo, transparent background. Fix and re-run until correct.
- Report in English: frames produced per class per animation, any frame you could not extract cleanly, contact sheet paths.
