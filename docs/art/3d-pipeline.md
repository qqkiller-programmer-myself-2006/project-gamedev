# 3D character pipeline (free tools)

Status: accepted by the owner on 2026-10-03. Owner chose **full 3D anime characters in battle**, matching the mood of the reference battle screenshot (characters as real 3D models on the stage, dynamic slanted HUD on top). This supersedes the earlier recommendation of sprite 2.5D.

Constraints: free tools only, Godot 4.7.2 `gl_compatibility` renderer, Web + Windows export. Reference images set mood only; every model and outfit is our own design (see `docs/design/character-designs-draft.md`).

## Pipeline

| Step | Tool | Who | Output |
| --- | --- | --- | --- |
| 1. Character sheet (front/side/back, 5 expressions) | Codex image generation, prompts in `docs/art/prompt-pack.md` | Codex, reviewed by Claude | PNG sheet per character |
| 2. Base model | **VRoid Studio** (free, anime-focused: hair, glasses, face, outfit textures) | Owner by hand (GUI), using the sheet as reference | `.vrm` per character |
| 3. Outfit/texture touch-up | VRoid texture editor, Krita/GIMP | Owner or Codex for texture images | updated `.vrm` |
| 4. Import to Godot | **godot-vrm** addon (V-Sekai, MIT) | Codex/agy | `.vrm` imported scenes, MToon toon shading |
| 5. Animations | **Mixamo** (free, Adobe account) FBX: idle, run, strike, skill cast, guard, hurt, die, victory, heal, item | Owner downloads; Codex/agy retargets with Godot `BoneMap` + `SkeletonProfileHumanoid` | shared `AnimationLibrary` for all humanoids |
| 6. Class weapons/props | Blender (free) or simple Godot meshes | Codex/agy | attached to hand bones per Class |
| 7. Effects | Godot `CPUParticles3D` + shaders (CPU particles for compatibility/Web) | Codex/agy | per-cue effect scenes |
| 8. Enemies/bosses | VRoid for humanoid demons (horns as hair/accessory meshes); non-humanoid monsters from free image-to-3D (Tripo/Meshy free tier) as fallback | Owner + Codex | `.glb`/`.vrm` |

## Integration rules
- Models plug into `Battle3DStage` (T3D-03) by replacing the placeholder unit meshes; the stage API (`apply_state`, `play_cue`, `unit_screen_position`) stays the same. Cue names map 1:1 to animation names.
- Story outfit is the same for every Class; Class changes only swap the weapon/prop (matches cutscene rule).
- Every model/animation is recorded in `assets/MANIFEST.3d.json` with tool, source and license (Mixamo animations: free to use in games, not redistributable as raw files).

## Budgets (Web-safe)
- Per character ≤ 25k triangles after VRoid reduction, ≤ 4 materials, textures ≤ 1024².
- Battle scene ≤ 10 skinned characters on screen.
- Measure with `tools/dev/qa3d_perf.gd`; fall back to lower texture size on Web if frame time exceeds the T3D-05 baseline.

## Risks
- VRoid modeling is manual GUI work (~2–4 hours per character for the owner); AI cannot do this step directly.
- MToon on `gl_compatibility`: verify on the first imported model before producing the rest; fallback is Godot's own toon shader.
- Mixamo retarget can bend fingers/shoulders on VRoid rigs; verify with one character first.

## First milestone
One character (IQ) end to end: sheet, VRoid model, import, 4 animations (idle, strike, hurt, die), shown in `Battle3DStage` under `--3d`, Web build checked for frame time.
