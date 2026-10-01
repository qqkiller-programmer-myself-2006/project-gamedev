# T42 — More motion in the skill FX (continue T40; production soon)

Context: `tools/art/make_skill_fx.py` generates the 10 skill FX strips (`art_source/fx/`, `assets/fx/<skill>/frame_NN.png`,
`assets/fx/manifest.json`, slicer `tools/art/slice_skill_fx.py`, player `src/client/match/battle/skill_fx.gd`). The art style and
positions are approved. Problem: several skills look nearly static (frames differ by a pixel or two), so they read as flicker.

## Do
Rework only the frame generation so every skill has clear motion over its frames (keep the same names, canvas sizes, frame counts
or raise counts up to 10/12 for ultimate-tier; update the manifest `frames`/`fps` accordingly; keep the 8 px transparent margin
assert and the palette/outline style):
- power_slash: crescent sweeps across the canvas (starts thin at upper-right, grows to full arc, then fades with trailing sparks).
- aimed_shot: bolt travels from left edge to centre with a motion trail, then impact star expands and fades.
- fireball: small ember grows, wobbling flame edge, explosion ring expands, embers fly outward and fade.
- frost_lance: spear streaks in, ice shards burst radially and fall/fade; add a brief frost ring.
- protect: shield scales in with a pop (overshoot), pulse ring expands once, soft glow fades.
- shield_wall: three shields rise/slide in one after another, glow pulse across them, fade out.
- stab: dagger streak snaps in, cross glint flashes at the hit with radial lines growing then shrinking.
- prep_time: blade appears, green venom drips run down and sparkle; drops fall across frames.
- poke_up: shaft thrusts upward from below, then impact burst + dust puffs.
- inject_venom: syringe plunges, purple liquid flows, green bubbles/drops rise and pop.
Use easing (not linear) for position/scale, and vary alpha (fade in/out). Frames must differ visibly: add an automated check
in `slice_skill_fx.py` that consecutive frames differ in at least ~2% of pixels (and not all frames identical), failing otherwise.
fps 14-18 is fine; `SkillFx` already reads `frames`/`fps` from the manifest — change `skill_fx.gd` only if needed.

## Verify
- Regenerate, re-slice, `"$GODOT" --headless --path . --import`, make `assets/fx/_contact.png` (2x scale, navy bg, 8 px grid) AND
  `assets/fx/_motion.png` showing frame-to-frame difference per skill; LOOK at them and iterate until each strip clearly animates.
- Tests: run `tests/client/test_skill_fx.gd` (update it if frame counts change) and the full suite
  (`GODOT=D:\dev-tools\godot\Godot_v4.7.2-stable_win64_console.exe bash tools/run_tests.sh`). Other sessions' Godot may be running; accepted.
- Only touch: `tools/art/*skill_fx*.py`, `art_source/fx/**`, `assets/fx/**`, `tests/client/test_skill_fx.gd`, and `skill_fx.gd` if needed.
- Do not commit. Report in English: per-skill frame counts and what moves, test summary line, paths of the contact sheets.
