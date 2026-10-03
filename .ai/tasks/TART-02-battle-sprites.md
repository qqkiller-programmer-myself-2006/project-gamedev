# TART-02 — Battle sprites and portraits (after the owner locks the sheets)

- **Task ID:** TART-02
- **Owner:** Codex (image generation) + Claude 1 (chroma-key script, manifest, QA)
- **Dependencies:** TART-01 done **and the owner has picked one sheet per character** (put the chosen file at `art_source/sheets/<character>/locked.png`). Do not start before that. Needs a separate owner go-ahead for the Codex run.
- **Read first:** `docs/art/2-5d-pipeline.md`, `docs/art/prompt-pack.md` (Part 1 class overlays + Portrait), `assets/MANIFEST.3d.json`, `tools/art/check_manifest.py`

## Goal
Final art for the 2.5D battle: for each character, `idle` per class (15), `hurt` and `down` (10), portraits normal/hurt/defeated (15), as transparent PNGs in the paths `T25D-01` reads.

## Scope
1. **Codex:** generate each image on flat #00FF00 green using the locked sheet as reference. Class idle images use the "class overlay" prompt (same face and outfit, new weapon/accessory). Battle sprites: full body, 3/4 view facing screen-right, feet visible, consistent scale (head-to-toe fills ~90% of the frame height). Save raw to `art_source/battle/<unit_key>/<pose>_raw.png`; portraits to `art_source/portraits/<character>/<state>_raw.png`.
2. **Chroma key script** `tools/art/chroma_key.py` (Pillow; edge feather, despill, trim to content then pad to a common canvas so feet line up) with a small unit test or a self-check mode. Output to `assets/art/battle/<unit_key>/<pose>.png` and `assets/art/portraits/<character>/<state>.png`.
3. **QA by Claude 1:** compare each result with the locked sheet (hair/eye color, glasses, signature item, coat lining); regenerate failures; check both on a dark and a light background; file size ≤ 1.5 MB each.
4. **Manifest:** one entry per file in `assets/MANIFEST.3d.json` (prompt, tool, seed, date, license); `python tools/art/check_manifest.py` passes.
5. Import into Godot (`--headless --path . --import`) and run the suite; show 3 screenshots with the sprites in `Battle3DStage`.

## Allowed paths
`art_source/**`, `assets/art/**`, `tools/art/chroma_key.py`, `assets/MANIFEST.3d.json`, `docs/screenshots/battle25d/**`

## Forbidden paths
`src/**`, `content/**`, `i18n/**`

## Acceptance criteria
40 images present with alpha, manifest valid, suite green, owner reviews screenshots.

## Handoff
`.ai/handoff/TART-02.md`: counts, failures regenerated, known weak images, manifest check result.
