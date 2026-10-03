# T25D-01 — 2.5D sprite units in `Battle3DStage`

- **Task ID:** T25D-01
- **Owner:** Claude 2 (`ai/3d-claude2`, worktree `Project-GameDev-Agents/Claude2`)
- **Dependencies:** T3D-03/T3D-06 merged (done). Real art from TART-02 is **not** required: build with placeholder sprites first.
- **Read first:** `AGENTS.md`, `docs/art/2-5d-pipeline.md`, `docs/adr/0015-3d-presentation-offline-story-slice.md`, `src/client/match/battle3d/battle3d_stage.gd` (`Rig`, `_make_rig`, `_build_model`, `_animate_rig`, `_pose`, `_spawn_effect`), `src/client/presentation/battle_presentation.gd`

## Goal
Render each unit as a camera-facing sprite on the existing stage, driven by the same state and cues, so real character art can be dropped in later without code changes.

## Scope
1. **Sprite rig:** replace the box/cylinder model in `_build_model` with a `Sprite3D` (billboard around Y only, `alpha_cut`/alpha blend, unshaded + optional rim) plus a soft round ground shadow. Keep rings/markers, picking (`pick_unit`, `PICK_RADIUS_FACTOR`), `unit_screen_position`, `unit_head_screen_position` working (anchor from sprite height).
2. **Art lookup (data-driven):** `res://assets/art/battle/<unit_key>/<pose>.png` with `unit_key` = character id + class (e.g. `iq_assassin`) for party and enemy id for enemies; poses `idle`, `hurt`, `down`. Fallback chain: missing pose → `idle`; missing unit → generated placeholder silhouette texture (dark coat shape with red edge, class-colored accent) created in code. Never crash on a missing file.
3. **Code motion per cue** (all disabled/reduced under `reduced_motion`, final state still correct): `strike` lunge to target and back; `skill` hop + glow ring; `focus` slow pulse; `item` small hop; `guard` crouch/squash + shield flash; `hurt` swap to `hurt` pose + shake + red flash; `die` swap to `down` pose + fade/tilt; `heal` green/white sparkle. Reuse the stage's existing effect/camera push code.
4. **Facing/side:** party sprites face right (toward enemies), enemy sprites face left; flip horizontally in the shader/`flip_h` rather than shipping mirrored art.
5. **Quality:** `set_quality(low)` uses smaller textures/no shadow blur. Keep `tools/dev/qa3d_perf.gd` frame time at or below the T3D-05 baseline.
6. **Tests** (`tests/client/battle3d/` — extend the existing T3D-03 tests): placeholder generation, missing-file fallback, picking still returns the right id, head anchor above feet, each cue ends in a consistent final state, reduced motion produces no offset, flip by side.
7. **Screenshots** 1280×720 and 1920×1080 with the HUD on (`--3d`): idle party vs enemies, strike mid-lunge, hurt, a downed unit. Put under `docs/screenshots/battle25d/`.

## Allowed paths
`src/client/match/battle3d/**`, `tests/client/battle3d/**` (or the existing test dir for battle3d), `assets/art/battle/**` (placeholders only if generated to disk), `docs/screenshots/battle25d/**`, `tools/dev/ui_preview.gd`, `i18n/**` (only if a visible string is added)

## Forbidden paths
`src/match/**`, `src/net/**`, `src/server/**`, `content/**`, `src/client/match/battle/**` (HUD), `src/client/home3d/**`, `assets/MANIFEST.3d.json` (Claude 1 owns manifest entries)

## Acceptance criteria
1. All new tests pass; `GODOT=D:/dev-tools/godot/Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh` green, count not reduced.
2. Without `--3d` nothing changes. With `--3d` a full combat plays with sprites, HUD intact.
3. Dropping a PNG at `assets/art/battle/iq_assassin/idle.png` replaces the placeholder with no code change (show it in a test or screenshot).

## Handoff
`.ai/handoff/T25D-01.md`: branch + sha, files, test result, screenshot paths, perf numbers, open questions. Commit on `ai/3d-claude2`, never push.
