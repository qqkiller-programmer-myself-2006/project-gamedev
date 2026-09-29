# T9a round 2 — slice the character sheets correctly (Python + Pillow)

Read `.ai/tasks/T9a-slice-character-sheets.md` (the original spec; same file limits). Round 1 ran inside a sandbox without
Python and produced broken frames: QA's view of `assets/characters/archer/_contact.png` shows most frames empty or showing
only a sliver of the character. **Delete every generated PNG and `manifest.json` under `assets/characters/<class>/`** (keep
`assets/characters/source/`) and regenerate with `python tools/slice_character_sheet.py` — Python 3.13 and Pillow 12 are
installed on this machine (`python -c "import PIL"` works; numpy is NOT installed, use Pillow only). Fix the script as needed.
If `python` is not found, use the full path `C:\Users\qqkiller2006\AppData\Local\Programs\Python\Python313\python.exe`.
If Python still cannot run, STOP and report the exact error — do not fall back to a Godot script again.

## Measured layout (QA measured foreground rows in x ≥ 345, background RGB (22,27,33), colour-distance > 60)

| Row band (y px) | archer | mage | swordsman |
| --- | --- | --- | --- |
| Idle (4 frames + labels below) | 70–162 | 71–177 | 74–180 |
| Walk | 268–341 | 275–350 | 291–365 |
| Run | 445–519 | 445–519 | 482–555 |
| Attack (full width, x ≥ 20) | 601–697 | 580–699 | 642–740 |
| Hurt (x < 440) and Dead (x 500–930) | 800–876 | 805–875 | 848–924 |

Groups inside Walk/Run/Attack are separated by thin vertical divider lines (roughly x ≈ 555, 783, 1013 for Walk/Run and
x ≈ 325, 622, 952 for Attack) — detect the dividers, then split blobs by group: Down, Left, Right, Up.
Frames are ~60–80 px tall. Label words ("Down", "Left", "Attack (โจมตี)") are thin text: drop components shorter than
~30 px or that sit below the frame baseline. Attack effects (arrows, slash arcs, magic orbs) that touch or sit next to a
frame belong to that frame — merge components whose bounding boxes are within ~12 px horizontally in the same group.

Bottom area (y > 900): the weapon box (x ≈ 25–220), the In-game box (ignore), skill icons row (x ≈ 540–870, y ≈ 940–1030 —
icons have their own dark tile background; crop each tile, drop the text label under it), splash art (x > 560, y > 930).
Portrait = the big art in x < 345, y < 560.

## Output (per class) — as in the original spec

`idle_{down,left,right,up}.png`, `walk_*`, `run_*`, `attack_{down,left,right,up}_N.png`, `hurt_0..4.png`, `dead_0..3.png`,
`portrait.png`, `splash.png`, `weapon.png`, `skill_0..n.png`, `_contact.png` (checkerboard background, labelled), plus
`assets/characters/manifest.json`. Frames of one animation share one canvas size, bottom-centre aligned.

## Verify (mandatory)

Open each `_contact.png` (view the image) and confirm: every frame shows a whole character (head to feet), attack frames keep
their effects, no label text, transparent background with no dark halo. Iterate until true for all three classes.
Report in English: frame counts per animation per class and anything still imperfect.
