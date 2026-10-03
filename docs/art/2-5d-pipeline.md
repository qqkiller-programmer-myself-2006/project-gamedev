# 2.5D battle pipeline (replaces the 3D-model plan for battle)

Status: accepted by the owner on 2026-10-03. The owner chose **2.5D**: character art is drawn/generated as 2D cutouts that stand on the existing 3D stage (`Battle3DStage`). This supersedes `docs/art/3d-pipeline.md` for battle units. A full 3D model of one character may still be tried later (the stage API does not change), but it is not on the critical path and needs the owner's go-ahead.

Mood target: the Persona-like reference the owner supplied (dark stage, slanted black/red/white HUD, dramatic silhouettes). Original designs only; the reference sets mood, nothing is copied.

## What 2.5D means here
- Each unit is a camera-facing sprite quad (`Sprite3D`, billboard on Y) with a soft ground shadow, placed in the existing stage slots. Backgrounds and floor stay 3D.
- Motion is done in code, not in art: lunge toward the target, hop, shake, tilt, flash, red rim pulse, fade/collapse. Art only needs a few poses.
- Existing contract does not change: `apply_state`, `play_cue` (strike, skill, focus, item, guard, hurt, die, heal), `unit_screen_position`, `unit_head_screen_position`, `pick_unit`, `set_reduced_motion`, `set_quality`. The HUD (T3D-07) keeps working untouched.

## Art needed (version 1)
| Item | Count | Notes |
| --- | --- | --- |
| Character sheets (front/side/back + 5 faces) | 6 main (IQ, Fifa, Tata, Cake, May, Nanny) | owner picks and locks faces first |
| Battle sprite `idle` per character × class | 15 (men: assassin/archer/guardian, women: mage/support/healer) | full body, 3/4 view facing the enemies, transparent background |
| Battle sprite `hurt` and `down` | 2 per character = 10 | class-independent where possible (weapon hidden or generic) |
| Portraits normal/hurt/defeated | 3 per character = 15 | for the HUD plates |
| Enemy sprites | 1 per enemy type in `forest.json` | later task |
| Effects | existing `assets/` fx first | new Story-only fx later |

Strike/skill/guard/heal are shown by moving the `idle` sprite plus effects, so they need no extra art in v1.

## Transparent backgrounds
Generate on flat green (#00FF00), remove the key with a script in `tools/art/` (`chroma_key.py`, Pillow, edge-feathered, no green spill), save as PNG with alpha. Check every sprite on a dark and a light background. Size: 1024×1536 max, power-of-two not required; downscale for `low_quality`.

## Tools
- Images: Codex image generation (prompts in `docs/art/prompt-pack.md`, already original-design only). Claude 1 checks each result against the locked character sheet.
- Locking: the owner approves each character sheet before sprites are made; sprites use the locked sheet as the reference image.
- Every file gets an entry in `assets/MANIFEST.3d.json` (prompt, tool, seed if any, date, license) and passes `python tools/art/check_manifest.py`.

## Order
1. TART-01: character sheets for the 6 main characters → owner locks.
2. TART-02: battle sprites (idle × class, hurt, down) and portraits → chroma-key → manifest.
3. T25D-01: `Battle3DStage` renders sprites (billboard, shadow, code motion). Can start now with placeholder sprites generated from the existing silhouette rigs; swap to real art when TART-02 lands.
4. Enemies and backgrounds afterwards.

## Risks
- Face consistency across many generated images → always pass the locked sheet as reference; reject and regenerate otherwise.
- Glasses (all women) and hands are the usual failure points → check these first on each image.
- Billboard sprites look flat if the camera orbits → keep the camera push/shake already in the stage, no orbit.
