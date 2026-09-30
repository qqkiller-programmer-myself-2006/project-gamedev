# Guardian generated-sheet mapping

Source (kept, never edited): `guardian_generated_spritesheet.png` (1671x941,
transparent background; 2 rows x 3 columns of chibi Guardian poses).

Derived runtime frames (new files; original v2 frames are preserved untouched):

| Source cell        | Output file                        | Canvas   | Baseline |
| ------------------ | ---------------------------------- | -------- | -------- |
| top-left           | `guardian_generated_idle_right.png` | 90x78    | 73       |
| bottom-left        | `guardian_generated_attack_00.png` | 256x106  | 103      |
| bottom-middle      | `guardian_generated_attack_01.png` | 256x106  | 103      |
| bottom-right       | `guardian_generated_attack_02.png` | 256x106  | 103      |

Method: tight transparent-bbox crop per cell (+4 px margin), aspect-fit scale
into the existing v2 canvas, horizontally centered, feet aligned to the
existing v2 content bottom (idle 71 px, attack ~95 px) so `SpriteSet`
canvas/baseline values in `assets/heroes/manifest.json` are unchanged.
`manifest.json` guardian `idle` right entry and `attack.right` list point at
these files; every other direction, class, canvas, baseline, and fps entry is
untouched. Note: the bottom-right cell carries a slash-effect tail at its
left edge exactly as laid out in the source sheet.
